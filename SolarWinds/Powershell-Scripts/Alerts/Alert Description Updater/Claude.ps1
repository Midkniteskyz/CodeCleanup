function Parse-SolarWindsAlert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TriggerXml,
        
        [Parameter(Mandatory=$true)]
        [string]$ResetXml,
        
        [Parameter(Mandatory=$false)]
        [string]$NotificationSettingsXml,
        
        [Parameter(Mandatory=$false)]
        [string]$AlertName = "Unknown Alert",
        
        [Parameter(Mandatory=$false)]
        [string]$TimeSchedule = "Alert is always enabled"
    )
    
    # Function to parse field mappings for human-readable output
    function Get-FieldDisplayName {
        param([string]$FieldPath)
        
        $fieldMappings = @{
            "Orion.Nodes|Status" = "Node Status"
            'Orion.Nodes|Caption' = 'Node Name'
            "Orion.NodesCustomProperties|Infrastructure|CustomProperties" = "Nodes Custom Properties - Infrastructure"
            "Orion.NodesCustomProperties|PrimaryContacts|CustomProperties" = "Node Custom Properties - Primary Contacts"
            "Orion.Interfaces|Status" = "Interface Status"
            "Orion.Volumes|Status" = "Volume Status"
            "Orion.APM.Application|Status" = "Application Status"
        }
        
        if ($fieldMappings.ContainsKey($FieldPath)) {
            return $fieldMappings[$FieldPath]
        }
        return $FieldPath
    }
    
    # Function to parse operator mappings
    function Get-OperatorDisplayName {
        param([string]$Operator)
        
        $operatorMappings = @{
            "=" = "is equal to"
            "!=" = "is not equal to"
            ">" = "is greater than"
            "<" = "is less than"
            ">=" = "is greater than or equal to"
            "<=" = "is less than or equal to"
            "LIKE" = "contains"
            "NOT LIKE" = "does not contain"
            "ISNOTNULL" = "is not null"
            "ISNULL" = "is null"
        }
        
        if ($operatorMappings.ContainsKey($Operator)) {
            return $operatorMappings[$Operator]
        }
        return $Operator
    }
    
    # Function to parse value mappings
    function Get-ValueDisplayName {
        param([string]$Value, [string]$Field)
        
        # Status value mappings
        if ($Field -like "*Status*") {
            $statusMappings = @{
                "1" = "Up"
                "2" = "Down"
                "3" = "Warning"
                "9" = "Unknown"
            }
            if ($statusMappings.ContainsKey($Value)) {
                return $statusMappings[$Value]
            }
        }
        
        return $Value
    }
    
    # Function to parse the expression tree from trigger XML

    function Parse-ExpressionTree {
        param([System.Xml.XmlNode]$ExprNode)
        
        if (-not $ExprNode) {
            return "No expression found"
        }
        
        $nodeType = $ExprNode.NodeType
        $value = $ExprNode.Value
        
        if ($nodeType -eq "Operator") {
            # Get child nodes - they should be in Child elements
            $childNodes = @()
            foreach ($child in $ExprNode.Child) {
                if ($child.Expr) {
                    $childNodes += $child.Expr
                }
            }
            
            if ($value -eq "AND" -or $value -eq "OR") {
                # Logical operators - should have exactly 2 children
                if ($childNodes.Count -ge 2) {
                    $leftExpr = Parse-ExpressionTree $childNodes[0]
                    $rightExpr = Parse-ExpressionTree $childNodes[1]
                    return "($leftExpr $value $rightExpr)"
                } else {
                    return "Invalid logical expression structure"
                }
            } elseif ($value -eq "ISNOTNULL" -or $value -eq "ISNULL") {
                # Unary operators - should have exactly 1 child
                if ($childNodes.Count -ge 1) {
                    $field = Get-FieldDisplayName $childNodes[0].Value
                    $operatorText = Get-OperatorDisplayName $value
                    return "$field $operatorText"
                } else {
                    return "Invalid unary expression structure"
                }
            } else {
                # Binary comparison operators - should have exactly 2 children
                if ($childNodes.Count -ge 2) {
                    $field = Get-FieldDisplayName $childNodes[0].Value
                    $compareValue = Get-ValueDisplayName $childNodes[1].Value $childNodes[0].Value
                    $operatorText = Get-OperatorDisplayName $value
                    return "$field $operatorText $compareValue"
                } else {
                    return "Invalid binary expression structure"
                }
            }
        }
        
        return $value
    }

    # Parse Trigger Condition
    $triggerCondition = "Unable to parse trigger condition"
    $scopeCondition = "No scope defined"
    
    try {
        [xml]$triggerXmlDoc = $TriggerXml
        $alertCondition = $triggerXmlDoc.ArrayOfAlertConditionShelve.AlertConditionShelve
        
        if ($alertCondition.Configuration) {
            # Decode the inner XML
            $decodedConfig = [System.Web.HttpUtility]::HtmlDecode($alertCondition.Configuration)
            [xml]$configXml = $decodedConfig
            
            # Parse the main expression tree
            if ($configXml.AlertConditionDynamic.ExprTree.Child.Expr) {
                $triggerCondition = Parse-ExpressionTree $configXml.AlertConditionDynamic.ExprTree.Child.Expr
            }
            
            # Parse the scope condition
            if ($configXml.AlertConditionDynamic.Scope.Child.Expr) {
                $scopeCondition = Parse-ExpressionTree $configXml.AlertConditionDynamic.Scope.Child.Expr
            }
        }
    }
    catch {
        Write-Warning "Error parsing trigger condition: $($_.Exception.Message)"
        Write-Debug "Full error: $($_.Exception)"
    }
    
    # Parse Reset Condition
    $resetCondition = "Unable to parse reset condition"
    
    try {
        [xml]$resetXmlDoc = $ResetXml
        $resetAlertCondition = $resetXmlDoc.ArrayOfAlertConditionShelve.AlertConditionShelve
        
        if ($resetAlertCondition.ChainType -eq "ResetInverseToTrigger") {
            $resetCondition = "When the trigger condition is no longer true"
        } elseif ($resetAlertCondition.Configuration) {
            # Handle custom reset conditions
            $decodedResetConfig = [System.Web.HttpUtility]::HtmlDecode($resetAlertCondition.Configuration)
            [xml]$resetConfigXml = $decodedResetConfig
            
            if ($resetConfigXml.AlertConditionDynamic.ExprTree.Child.Expr) {
                $resetCondition = Parse-ExpressionTree $resetConfigXml.AlertConditionDynamic.ExprTree.Child.Expr
            }
        }
    }
    catch {
        Write-Warning "Error parsing reset condition: $($_.Exception.Message)"
    }
    
    # Parse Notification Settings (Actions)
    $triggerActions = @()
    $resetActions = @()
    
    if ($NotificationSettingsXml) {
        try {
            [xml]$notificationXml = $NotificationSettingsXml
            $notificationSetting = $notificationXml.AlertNotificationSetting
            
            if ($notificationSetting.Enabled -eq "true") {
                $triggerActions += "Escalation Level 1"
                $triggerActions += "1. Log Event"
                $triggerActions += "2. Send Email - Subject: $($notificationSetting.Subject)"
                
                # Parse properties if they exist
                if ($notificationSetting._properties) {
                    $triggerActions += "   Email Properties:"
                    foreach ($prop in $notificationSetting._properties.KeyValueOfstringAlertNotificationProperty9sQWCBBt) {
                        $triggerActions += "   - $($prop.Key): $($prop.Value.Value)"
                    }
                }
                
                $resetActions += "1. Log Event"
                $resetActions += "2. Send Email"
            }
        }
        catch {
            Write-Warning "Error parsing notification settings: $($_.Exception.Message)"
        }
    }
    
    # Build the output
    $output = @"

============================================
Alert Configuration: $AlertName
============================================

Scope (Objects to monitor):
$scopeCondition

Trigger Condition:
$triggerCondition

Reset Condition:
$resetCondition

Time of Day Schedule:
$TimeSchedule

Trigger Actions:
$($triggerActions -join "`n")

Reset Actions:
$($resetActions -join "`n")

============================================
"@
    
    return $output
}

# Function to help debug XML structure
function Debug-XmlStructure {
    param([string]$XmlString, [string]$Name)
    
    Write-Host "=== DEBUG: $Name ===" -ForegroundColor Yellow
    try {
        [xml]$xmlDoc = $XmlString
        $alertCondition = $xmlDoc.ArrayOfAlertConditionShelve.AlertConditionShelve
        
        if ($alertCondition.Configuration) {
            $decodedConfig = [System.Web.HttpUtility]::HtmlDecode($alertCondition.Configuration)
            Write-Host "Decoded Configuration:" -ForegroundColor Cyan
            Write-Host $decodedConfig
            
            [xml]$configXml = $decodedConfig
            Write-Host "`nExpression Tree Structure:" -ForegroundColor Cyan
            $exprTree = $configXml.AlertConditionDynamic.ExprTree
            if ($exprTree.Child.Expr) {
                Write-Host "NodeType: $($exprTree.Child.Expr.NodeType)"
                Write-Host "Value: $($exprTree.Child.Expr.Value)"
                Write-Host "Child count: $($exprTree.Child.Expr.Child.Count)"
            }
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host "===================" -ForegroundColor Yellow
}

# Example usage function that demonstrates how to use with database query
function Get-AlertConfigurationReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory=$false)]
        [string]$AlertID,
        
        [Parameter(Mandatory=$false)]
        [string]$AlertName
    )
    
    # Build the SQL query
    $sql = @"
SELECT
  ac.AlertID,
  ac.Name,
  ac.Trigger,
  ac.Reset,
  ac.NotificationSettings
FROM Orion.AlertConfigurations AS ac
"@

    if ($AlertID) {
        $sql += " WHERE AlertID = '$AlertID'"
    } elseif ($AlertName) {
        $sql += " WHERE Name LIKE '%$AlertName%'"
    }
    
    try {
        # Note: You'll need to replace this with your actual database connection method
        # This is a placeholder for the database query
        Write-Host "Execute this SQL query against your SolarWinds database:"
        Write-Host $sql
        Write-Host ""
        Write-Host "Then call Parse-SolarWindsAlert with the results:"
        Write-Host 'Parse-SolarWindsAlert -TriggerXml $row.Trigger -ResetXml $row.Reset -NotificationSettingsXml $row.NotificationSettings -AlertName $row.Name'
    }
    catch {
        Write-Error "Error executing query: $($_.Exception.Message)"
    }
}

# Example with the data you provided
$exampleTrigger = '<ArrayOfAlertConditionShelve xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><AlertConditionShelve><AndThenTimeInterval i:nil="true"/><ChainType>Trigger</ChainType><ConditionTypeID>Core.Dynamic</ConditionTypeID><Configuration>&lt;AlertConditionDynamic xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Alerting.Plugins.Conditions.Dynamic" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"&gt;&lt;ExprTree xmlns:a="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting"&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Field&lt;/a:NodeType&gt;&lt;a:Value&gt;Orion.Nodes|Status&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Constant&lt;/a:NodeType&gt;&lt;a:Value&gt;2&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;=&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;a:Expr&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Field&lt;/a:NodeType&gt;&lt;a:Value&gt;Orion.NodesCustomProperties|PrimaryContacts|CustomProperties&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;ISNOTNULL&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;AND&lt;/a:Value&gt;&lt;/ExprTree&gt;&lt;Scope xmlns:a="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting"&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Field&lt;/a:NodeType&gt;&lt;a:Value&gt;Orion.Nodes|Caption&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Constant&lt;/a:NodeType&gt;&lt;a:Value&gt;L1S-ASA-TRAINING&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;=&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;AND&lt;/a:Value&gt;&lt;/Scope&gt;&lt;TimeWindow i:nil="true"/&gt;&lt;/AlertConditionDynamic&gt;</Configuration><ConjunctionOperator>None</ConjunctionOperator><IsInvertedMinCountThreshold>false</IsInvertedMinCountThreshold><NetObjectsMinCountThreshold i:nil="true"/><ObjectType>Node</ObjectType><SustainTime i:nil="true"/></AlertConditionShelve></ArrayOfAlertConditionShelve>'

$exampleReset = '<ArrayOfAlertConditionShelve xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><AlertConditionShelve><AndThenTimeInterval i:nil="true"/><ChainType>ResetCustom</ChainType><ConditionTypeID>Core.Dynamic</ConditionTypeID><Configuration>&lt;AlertConditionDynamic xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Alerting.Plugins.Conditions.Dynamic" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"&gt;&lt;ExprTree xmlns:a="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting"&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Field&lt;/a:NodeType&gt;&lt;a:Value&gt;Orion.Nodes|Status&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Constant&lt;/a:NodeType&gt;&lt;a:Value&gt;1&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;=&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;AND&lt;/a:Value&gt;&lt;/ExprTree&gt;&lt;Scope xmlns:a="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting"&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Field&lt;/a:NodeType&gt;&lt;a:Value&gt;Orion.Nodes|Caption&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Constant&lt;/a:NodeType&gt;&lt;a:Value&gt;L1S-ASA-TRAINING&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;=&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;AND&lt;/a:Value&gt;&lt;/Scope&gt;&lt;TimeWindow i:nil="true"/&gt;&lt;/AlertConditionDynamic&gt;</Configuration><ConjunctionOperator>None</ConjunctionOperator><IsInvertedMinCountThreshold>false</IsInvertedMinCountThreshold><NetObjectsMinCountThreshold i:nil="true"/><ObjectType>Node</ObjectType><SustainTime i:nil="true"/></AlertConditionShelve></ArrayOfAlertConditionShelve>'

$exampleNotification = '<AlertNotificationSetting xmlns="http://schemas.solarwinds.com/2008/Core" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><Enabled>true</Enabled><NetObjectType>Node</NetObjectType><Severity>Informational</Severity><Subject>[TEST] rwoolsey - Node Alert Sample</Subject><_properties xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"><a:KeyValueOfstringAlertNotificationProperty9sQWCBBt><a:Key>IP Address</a:Key><a:Value><Name>IP Address</Name><Value>${IP_Address}</Value></a:Value></a:KeyValueOfstringAlertNotificationProperty9sQWCBBt><a:KeyValueOfstringAlertNotificationProperty9sQWCBBt><a:Key>Object Sub Type</a:Key><a:Value><Name>Object Sub Type</Name><Value>${ObjectSubType}</Value></a:Value></a:KeyValueOfstringAlertNotificationProperty9sQWCBBt><a:KeyValueOfstringAlertNotificationProperty9sQWCBBt><a:Key>Status Description</a:Key><a:Value><Name>Status Description</Name><Value>${StatusDescription}</Value></a:Value></a:KeyValueOfstringAlertNotificationProperty9sQWCBBt><a:KeyValueOfstringAlertNotificationProperty9sQWCBBt><a:Key>Node Name</a:Key><a:Value><Name>Node Name</Name><Value>${SysName}</Value></a:Value></a:KeyValueOfstringAlertNotificationProperty9sQWCBBt><a:KeyValueOfstringAlertNotificationProperty9sQWCBBt><a:Key>Vendor</a:Key><a:Value><Name>Vendor</Name><Value>${Vendor}</Value></a:Value></a:KeyValueOfstringAlertNotificationProperty9sQWCBBt></_properties></AlertNotificationSetting>'

# Test the function with your example data
Write-Host "Testing with provided example data:"
Parse-SolarWindsAlert -TriggerXml $exampleTrigger -ResetXml $exampleReset -NotificationSettingsXml $exampleNotification -AlertName "Network - Alert me when a node goes down"

# Uncomment the line below to debug the XML structure
Debug-XmlStructure -XmlString $exampleTrigger -Name "Trigger XML"