function Convert-SolarWindsAlertXmlSummary {
    param (
        [string]$EncodedConfigXml,
        [string]$Label = "Trigger Condition"
    )

    function Get-FieldLabel {
        param ($field)
        $map = @{
            'Orion.Nodes|Status' = 'Node - Status'
            'Orion.Nodes|Caption' = 'Node - Node Name'
            'Orion.NodesCustomProperties|PrimaryContacts|CustomProperties' = 'Nodes Custom Properties - PrimaryContacts'
        }
        return $map[$field] ?? $field
    }

    function Get-OperatorLabel {
        param ($op)
        $map = @{
            '=' = 'is equal to'
            '!=' = 'is not equal to'
            'ISNOTNULL' = 'is not empty'
            'ISNULL' = 'is empty'
        }
        return $map[$op] ?? $op
    }

    function Get-ValueLabel {
        param ($field, $val)
        if ($field -like '*Status*') {
            switch ($val) {
                '1' { return 'Up' }
                '2' { return 'Down' }
                '3' { return 'Warning' }
                '9' { return 'Unknown' }
                default { return $val }
            }
        }
        return $val
    }

function ParseExpr($node, $ns) {
    if (-not $node) { return }

    $typeNode = $node.SelectSingleNode("a:NodeType", $ns)
    $valueNode = $node.SelectSingleNode("a:Value", $ns)
    if (-not $typeNode -or -not $valueNode) { return "[Invalid Node]" }

    $type = $typeNode.InnerText
    $value = $valueNode.InnerText
    $children = $node.SelectNodes("a:Child/a:Expr", $ns)

    if ($type -eq 'Operator') {
        $opText = Get-OperatorLabel $value

        if ($value -eq 'AND' -or $value -eq 'OR') {
            $results = @("All child conditions must be satisfied ($value)")
            foreach ($c in $children) {
                $parsed = ParseExpr $c $ns
                if ($parsed -is [System.Collections.IEnumerable] -and -not ($parsed -is [string])) {
                    $results += $parsed
                } else {
                    $results += ,$parsed
                }
            }
            return $results
        }

        elseif ($value -eq 'ISNOTNULL' -or $value -eq 'ISNULL') {
            $fieldNode = $children[0].SelectSingleNode("a:Value", $ns)
            $field = if ($fieldNode) { $fieldNode.InnerText } else { "[Missing Field]" }
            return "$(Get-FieldLabel $field) - $opText"
        }

        elseif ($children.Count -eq 2) {
            $leftNode  = $children[0].SelectSingleNode("a:Value", $ns)
            $rightNode = $children[1].SelectSingleNode("a:Value", $ns)

            $left  = if ($leftNode) { $leftNode.InnerText } else { "[Missing Left]" }
            $right = if ($rightNode) { $rightNode.InnerText } else { "[Missing Right]" }

            return "$(Get-FieldLabel $left) - $opText - $(Get-ValueLabel $left $right)"
        }
    }

    return "[Unrecognized Expression]"
}


    # Decode and parse XML
    $decoded = [System.Web.HttpUtility]::HtmlDecode($EncodedConfigXml)
    [xml]$config = $decoded

    # Add namespace manager
    $nsm = New-Object System.Xml.XmlNamespaceManager($config.NameTable)
    $nsm.AddNamespace("a", "http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting")

    $output = @()
    $output += "$Label :"

    # Scope (if it exists)
    $scopeExpr = $config.AlertConditionDynamic.Scope?.Child?.SelectSingleNode("a:Expr", $nsm)
    if ($scopeExpr) {
        $output += "Alert on all objects where:"
        $output += ParseExpr $scopeExpr $nsm
    }

    # Condition
    $exprNodes = $config.AlertConditionDynamic.ExprTree?.Child?.SelectNodes("a:Expr", $nsm)
    if ($exprNodes -and $exprNodes.Count -gt 0) {
        $output += "The actual trigger condition:"
        foreach ($expr in $exprNodes) {
            $parsed = ParseExpr $expr $nsm
            if ($parsed -is [System.Collections.IEnumerable] -and -not ($parsed -is [string])) {
                $output += $parsed
            } else {
                $output += ,$parsed
            }
        }
    }



    return $output -join "`n"
}

# Connect to SolarWinds
$swis = Connect-Swis -Hostname "hco.loop1.ziti" -Username "L1SENG\RWoolsey" -Password "W@shingt0n22!"

# Get a single alert configuration
$alert = Get-SwisData $swis @"
SELECT
  ac.AlertID,
  ac.Name,
  ac.Trigger,
  ac.Reset,
  ac.NotificationSettings,
  ac.Uri
FROM Orion.AlertConfigurations AS ac
WHERE ac.AlertID = '385'
"@

# Load XML from SolarWinds database export
# [xml]$triggerXmlDoc = '<ArrayOfAlertConditionShelve xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><AlertConditionShelve><AndThenTimeInterval i:nil="true"/><ChainType>Trigger</ChainType><ConditionTypeID>Core.Dynamic</ConditionTypeID><Configuration>&lt;AlertConditionDynamic xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Alerting.Plugins.Conditions.Dynamic" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"&gt;&lt;ExprTree xmlns:a="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting"&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Field&lt;/a:NodeType&gt;&lt;a:Value&gt;Orion.Nodes|Status&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Constant&lt;/a:NodeType&gt;&lt;a:Value&gt;2&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;=&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;a:Expr&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Field&lt;/a:NodeType&gt;&lt;a:Value&gt;Orion.NodesCustomProperties|PrimaryContacts|CustomProperties&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;ISNOTNULL&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;AND&lt;/a:Value&gt;&lt;/ExprTree&gt;&lt;Scope xmlns:a="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting"&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Field&lt;/a:NodeType&gt;&lt;a:Value&gt;Orion.Nodes|Caption&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Constant&lt;/a:NodeType&gt;&lt;a:Value&gt;L1S-ASA-TRAINING&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;=&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;AND&lt;/a:Value&gt;&lt;/Scope&gt;&lt;TimeWindow i:nil="true"/&gt;&lt;/AlertConditionDynamic&gt;</Configuration><ConjunctionOperator>None</ConjunctionOperator><IsInvertedMinCountThreshold>false</IsInvertedMinCountThreshold><NetObjectsMinCountThreshold i:nil="true"/><ObjectType>Node</ObjectType><SustainTime i:nil="true"/></AlertConditionShelve></ArrayOfAlertConditionShelve>'
# [xml]$resetXmlDoc   = '<ArrayOfAlertConditionShelve xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><AlertConditionShelve><AndThenTimeInterval i:nil="true"/><ChainType>ResetCustom</ChainType><ConditionTypeID>Core.Dynamic</ConditionTypeID><Configuration>&lt;AlertConditionDynamic xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Alerting.Plugins.Conditions.Dynamic" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"&gt;&lt;ExprTree xmlns:a="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting"&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Field&lt;/a:NodeType&gt;&lt;a:Value&gt;Orion.Nodes|Status&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Constant&lt;/a:NodeType&gt;&lt;a:Value&gt;1&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;=&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;AND&lt;/a:Value&gt;&lt;/ExprTree&gt;&lt;Scope xmlns:a="http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting"&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Field&lt;/a:NodeType&gt;&lt;a:Value&gt;Orion.Nodes|Caption&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;a:Expr&gt;&lt;a:Child i:nil="true"/&gt;&lt;a:NodeType&gt;Constant&lt;/a:NodeType&gt;&lt;a:Value&gt;L1S-ASA-TRAINING&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;=&lt;/a:Value&gt;&lt;/a:Expr&gt;&lt;/a:Child&gt;&lt;a:NodeType&gt;Operator&lt;/a:NodeType&gt;&lt;a:Value&gt;AND&lt;/a:Value&gt;&lt;/Scope&gt;&lt;TimeWindow i:nil="true"/&gt;&lt;/AlertConditionDynamic&gt;</Configuration><ConjunctionOperator>None</ConjunctionOperator><IsInvertedMinCountThreshold>false</IsInvertedMinCountThreshold><NetObjectsMinCountThreshold i:nil="true"/><ObjectType>Node</ObjectType><SustainTime i:nil="true"/></AlertConditionShelve></ArrayOfAlertConditionShelve>'

[xml]$triggerXmlDoc = $alert.Trigger
[xml]$resetXmlDoc = $alert.Reset

$triggerEncoded = $triggerXmlDoc.ArrayOfAlertConditionShelve.AlertConditionShelve.Configuration
$resetEncoded   = $resetXmlDoc.ArrayOfAlertConditionShelve.AlertConditionShelve.Configuration

$triggerSummary = Convert-SolarWindsAlertXmlSummary -EncodedConfigXml $triggerEncoded -Label "Trigger Condition"
$resetSummary   = Convert-SolarWindsAlertXmlSummary -EncodedConfigXml $resetEncoded -Label "Reset Condition"

#"$triggerSummary`n`n$resetSummary"

$newDescription = "$triggerSummary`n`n$resetSummary"
Set-SwisObject -SwisConnection $swis -Uri $alert.uri -Properties @{Description = $newDescription}
