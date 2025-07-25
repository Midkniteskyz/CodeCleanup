function ConvertFrom-SolarWindsAlertXML {
    param(
        [Parameter(Mandatory=$true)]
        [string]$XmlString
    )
    
    # Field mapping dictionary for common SolarWinds fields
    $FieldMappings = @{
        'Orion.Nodes|Vendor' = 'Node - Vendor'
        'Orion.Nodes|Caption' = 'Node - Name'
        'Orion.Nodes|Status' = 'Node - Status'
        'Orion.Nodes|StatusDescription' = 'Node - Status Description'
        'Orion.Interfaces|Status' = 'Interface - Status'
        'Orion.Interfaces|Caption' = 'Interface - Name'
        'Orion.Interfaces|InterfaceSpeed' = 'Interface - Speed'
        'Orion.Volumes|Status' = 'Volume - Status'
        'Orion.Volumes|Caption' = 'Volume - Name'
        'Orion.Volumes|VolumePercentUsed' = 'Volume - Percent Used'
        'Orion.OLM.AlertMessage|RuleDefinitionID|OLMAlertMessage' = 'Log Analyzer Alert Message - Processing Rule'
        'Orion.OLM.AlertMessage|event|OLMAlertMessage' = 'Log Analyzer Alert Message event'
        'Orion.ResponseTime|Status' = 'Response Time - Status'
        'Orion.CPULoad|Status' = 'CPU Load - Status'
        'Orion.Memory|Status' = 'Memory - Status'
    }
    
    # Event type mappings
    $EventMappings = @{
        'Orion.OLM.AlertMessage|event|OLMAlertMessage' = 'Log Analyzer Alert Message event'
        '[customEvent].Orion.OLM.AlertMessage|event|OLMAlertMessage' = 'Log Analyzer Alert Message event'
        'Orion.Events|event' = 'System Event'
        'Orion.NodeEvents|event' = 'Node Event'
    }
    
    # Operator mappings
    $OperatorMappings = @{
        '=' = 'is equal to'
        '!=' = 'is not equal to'
        '>' = 'is greater than'
        '<' = 'is less than'
        '>=' = 'is greater than or equal to'
        '<=' = 'is less than or equal to'
        'LIKE' = 'contains'
        'NOT LIKE' = 'does not contain'
        'AND' = 'AND'
        'OR' = 'OR'
    }
    
    # Parse XML
    try {
        $xml = [xml]$XmlString
        $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $ns.AddNamespace("sw", "http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting")
        $ns.AddNamespace("dyn", "http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Alerting.Plugins.Conditions.Dynamic")
        $ns.AddNamespace("a", "http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting")
        
        $result = @()
        
        # Get the configuration XML (it's HTML encoded)
        $configNode = $xml.SelectSingleNode("//sw:Configuration", $ns)
        if ($configNode) {
            $decodedConfig = [System.Web.HttpUtility]::HtmlDecode($configNode.InnerText)
            $configXml = [xml]$decodedConfig
            
            # Create namespace manager for the decoded config XML
            $configNs = New-Object System.Xml.XmlNamespaceManager($configXml.NameTable)
            $configNs.AddNamespace("dyn", "http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Alerting.Plugins.Conditions.Dynamic")
            $configNs.AddNamespace("a", "http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting")
            
            # Parse Scope (filtering conditions)
            $scopeNode = $configXml.SelectSingleNode("//dyn:Scope", $configNs)
            if ($scopeNode) {
                $scopeConditions = Parse-ExpressionTree -Node $scopeNode -FieldMappings $FieldMappings -OperatorMappings $OperatorMappings -NamespaceManager $configNs
                if ($scopeConditions) {
                    $result += "Trigger Condition:"
                    $result += "Alert on all objects where:"
                    $result += $scopeConditions
                    $result += ""
                }
            }
            
            # Parse ExprTree (main trigger logic)
            $exprTreeNode = $configXml.SelectSingleNode("//dyn:ExprTree", $configNs)
            if ($exprTreeNode) {
                $triggerConditions = Parse-ExpressionTree -Node $exprTreeNode -FieldMappings $FieldMappings -OperatorMappings $OperatorMappings -EventMappings $EventMappings -NamespaceManager $configNs
                if ($triggerConditions) {
                    $result += "The actual trigger condition:"
                    $result += $triggerConditions
                }
            }
        }
        
        return $result -join "`n"
    }
    catch {
        Write-Error "Error parsing XML: $($_.Exception.Message)"
        return $null
    }
}

function Parse-ExpressionTree {
    param(
        [System.Xml.XmlNode]$Node,
        [hashtable]$FieldMappings,
        [hashtable]$OperatorMappings,
        [hashtable]$EventMappings = @{},
        [System.Xml.XmlNamespaceManager]$NamespaceManager
    )
    
    $expressions = @()
    
    # Find all expression nodes
    $exprNodes = $Node.SelectNodes(".//a:Expr", $NamespaceManager)
    
    foreach ($expr in $exprNodes) {
        $nodeTypeNode = $expr.SelectSingleNode("a:NodeType", $NamespaceManager)
        $valueNode = $expr.SelectSingleNode("a:Value", $NamespaceManager)
        
        $nodeType = if ($nodeTypeNode) { $nodeTypeNode.InnerText } else { $null }
        $value = if ($valueNode) { $valueNode.InnerText } else { $null }
        
        switch ($nodeType) {
            "Event" {
                if ($EventMappings.ContainsKey($value)) {
                    $eventName = $EventMappings[$value]
                } else {
                    $eventName = $value -replace '\|', ' - '
                }
                
                # Look for associated constants to determine frequency
                $childNodes = $expr.SelectNodes("a:Child//a:Expr", $NamespaceManager)
                $threshold = "0"
                foreach ($child in $childNodes) {
                    $childNodeTypeNode = $child.SelectSingleNode("a:NodeType", $NamespaceManager)
                    $childValueNode = $child.SelectSingleNode("a:Value", $NamespaceManager)
                    
                    $childNodeType = if ($childNodeTypeNode) { $childNodeTypeNode.InnerText } else { $null }
                    $childValue = if ($childValueNode) { $childValueNode.InnerText } else { $null }
                    
                    if ($childNodeType -eq "Constant" -and $childValue -match '^\d+$') {
                        $threshold = $childValue
                    }
                }
                
                $expressions += "$eventName ( must happened more than $threshold times )"
            }
            
            "Field" {
                # This is handled in conjunction with operators
                continue
            }
            
            "Operator" {
                if ($value -eq "AND" -or $value -eq "OR") {
                    # Find the operands for this operator
                    $operands = Parse-OperatorExpression -ExprNode $expr -FieldMappings $FieldMappings -OperatorMappings $OperatorMappings -NamespaceManager $NamespaceManager
                    if ($operands) {
                        $expressions += $operands
                    }
                }
            }
        }
    }
    
    # Add conjunction information
    if ($expressions.Count -gt 1) {
        $expressions += "All child conditions must be satisfied (AND)"
    }
    
    return $expressions
}

function Parse-OperatorExpression {
    param(
        [System.Xml.XmlNode]$ExprNode,
        [hashtable]$FieldMappings,
        [hashtable]$OperatorMappings,
        [System.Xml.XmlNamespaceManager]$NamespaceManager
    )
    
    $operatorNode = $ExprNode.SelectSingleNode("a:Value", $NamespaceManager)
    $operator = if ($operatorNode) { $operatorNode.InnerText } else { $null }
    $children = $ExprNode.SelectNodes("a:Child/a:Expr", $NamespaceManager)
    
    if ($children.Count -eq 2) {
        $left = $children[0]
        $right = $children[1]
        
        $leftTypeNode = $left.SelectSingleNode("a:NodeType", $NamespaceManager)
        $leftValueNode = $left.SelectSingleNode("a:Value", $NamespaceManager)
        
        $rightTypeNode = $right.SelectSingleNode("a:NodeType", $NamespaceManager)
        $rightValueNode = $right.SelectSingleNode("a:Value", $NamespaceManager)
        
        $leftType = if ($leftTypeNode) { $leftTypeNode.InnerText } else { $null }
        $leftValue = if ($leftValueNode) { $leftValueNode.InnerText } else { $null }
        $rightType = if ($rightTypeNode) { $rightTypeNode.InnerText } else { $null }
        $rightValue = if ($rightValueNode) { $rightValueNode.InnerText } else { $null }
        
        if ($leftType -eq "Field" -and $rightType -eq "Constant") {
            $fieldName = if ($FieldMappings.ContainsKey($leftValue)) { $FieldMappings[$leftValue] } else { $leftValue -replace '\|', ' - ' }
            $operatorText = if ($OperatorMappings.ContainsKey($operator)) { $OperatorMappings[$operator] } else { $operator }
            
            # Handle null values
            if ([string]::IsNullOrEmpty($rightValue)) {
                $rightValue = "null"
            }
            
            return "$fieldName - $operatorText - $rightValue"
        }
    }
    
    return $null
}

# Add required assembly for HTML decoding
Add-Type -AssemblyName System.Web

# Example usage function
function Test-SolarWindsParser {
    $sampleXml = @'
<ArrayOfAlertConditionShelve xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><AlertConditionShelve><AndThenTimeInterval i:nil="true"/><ChainType>Trigger</ChainType><ConditionTypeID>Core.Dynamic</ConditionTypeID><Configuration>&lt;AlertConditionDynamic xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Alerting.Plugins.Conditions.Dynamic" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"&gt;&lt;ExprTree xmlns:a="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting"&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child/&gt;&lt;a:NodeType&gt;Field&lt;/a:NodeType&gt;&lt;a:Value&gt;Orion.Nodes|Status&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;a:Expr&gt;&lt;a:Child/&gt;&lt;a:NodeType&gt;Constant&lt;/a:NodeType&gt;&lt;a:Value&gt;2&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;=&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;AND&lt;/a:Value&gt;&lt;/ExprTree&gt;&lt;Scope xmlns:a="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting"&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Field&lt;/a:NodeType&gt;&lt;a:Value&gt;Orion.NodesCustomProperties|Infrastructure|CustomProperties&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Constant&lt;/a:NodeType&gt;&lt;a:Value&gt;Server&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;=&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;AND&lt;/a:Value&gt;&lt;/Scope&gt;&lt;TimeWindow i:nil="true"/&gt;&lt;/AlertConditionDynamic&gt;</Configuration><ConjunctionOperator>None</ConjunctionOperator><IsInvertedMinCountThreshold>false</IsInvertedMinCountThreshold><NetObjectsMinCountThreshold i:nil="true"/><ObjectType>Node</ObjectType><SustainTime>PT1M</SustainTime></AlertConditionShelve></ArrayOfAlertConditionShelve>
'@
    
    Write-Host "Testing SolarWinds XML Parser:" -ForegroundColor Yellow
    Write-Host "================================" -ForegroundColor Yellow
    $result = ConvertFrom-SolarWindsAlertXML -XmlString $sampleXml
    Write-Host $result
}

# Uncomment the line below to test with your sample XML
Test-SolarWindsParser