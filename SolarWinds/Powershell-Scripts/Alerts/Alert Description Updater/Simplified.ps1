function Parse-Conditions {
    param (
        $condition
    )

    # get all conditions
    Write-Host "Condition Count: $($condition.Child.Expr.count)"


    
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
  ac.NotificationSettings
FROM Orion.AlertConfigurations AS ac
WHERE ac.AlertID = '385'
"@

# Convert embedded XML safely
$triggerXml = [xml]$alert.Trigger
$resetXml = [xml]$alert.Reset
$notifyXml = [xml]$alert.NotificationSettings

# Example: Parse trigger condition
$expr = $triggerXml.ArrayOfAlertConditionShelve.AlertConditionShelve.Configuration

if ($expr) {
    #$config = [xml]$expr.InnerXml
    $config = [xml]$expr

    $conditions = $config.AlertConditionDynamic.ExprTree
    $scope      = $config.AlertConditionDynamic.Scope

    Write-Host "Trigger Condition:"
    Write-Host "Alert on all objects where:"
    Write-Host "Scope: $(Convert-ObjectType ($scope.Child.Expr.Child.Expr[0].Value)) $(Get-OperatorDisplayName ($scope.Child.Expr.Value)) $($scope.Child.Expr.Child.Expr[1].Value)"
    Write-Host "The actual trigger condition:"
    Write-Host "Condition: $($conditions.Child.Expr.Value) $($conditions.Child.Expr.Value)"
}

# # Example: Parse Reset
# if (-not $resetXml.ArrayOfAlertConditionShelve.AlertConditionShelve.Configuration) {
#     Write-Host "`nReset Condition:"
#     Write-Host "When the trigger condition is no longer true"
# }

# # Example: Time of Day (not in your provided sample, usually via Schedule table or TimeWindow in XML)
# Write-Host "`nTime of Day schedule:"
# Write-Host "Alert is always enabled"

# # Example: Parse Notification Settings
# Write-Host "`nTrigger Action:"
# foreach ($kvp in $notifyXml.AlertNotificationSetting._properties.'KeyValueOfstringAlertNotificationProperty9sQWCBBt') {
#     $key = $kvp.Key
#     $val = $kvp.Value.Value
#     Write-Host " - $key : $val"
# }
