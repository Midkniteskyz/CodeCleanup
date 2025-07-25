#requires -Modules @{ ModuleName = "SwisPowerShell"; ModuleVersion = "3.0.0.0" }

#region Variable Definition
$SwisHost = "solarWindsServer.yourDomain.local" # or IP Address
$OutputPath = Get-Location
#endregion Variable Definition

#region Remove Invalid File Name Characters
function Remove-InvalidFileNameChars {
  param(
    [Parameter(Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [String]$Name
  )

  $InvalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
  $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
  return ($Name -replace $re)
}
#endregion Remove Invalid File Name Characters

$SwisConnection = Connect-Swis -Hostname $SwisHost -Credential ( Get-Credential -Title "SolarWinds Platform Credentials" -Message "Enter your SolarWinds Platform individual account credentials" )
$Alerts = Get-SwisData -SwisConnection $SwisConnection -Query @"
SELECT [Alerts].AlertID
     , [Alerts].Name
FROM Orion.AlertConfigurations AS [Alerts]
WHERE [Alerts].[Canned] = 'FALSE'
ORDER BY [Alerts].[Name]
"@
For ( $i = 0; $i -lt $Alerts.Count; $i++ ) {
    Write-Progress -Activity "Exporting Alerts" -PercentComplete ( ( $i / $Alerts.Count ) * 100 )
    Write-Progress -Activity "Exporting Alerts" -Status "Extracting XML from Alert"
    $AlertBody = [xml]( Invoke-SwisVerb -SwisConnection $SwisConnection -EntityName 'Orion.AlertConfigurations' -Verb 'Export' -Arguments $Alerts[$i].AlertID | Select-Object -ExpandProperty '#text' )
    $AlertFile = "$( ( $AlertBody.AlertDefinition.Name + "_" + ( [int]( $AlertBody.AlertDefinition.AlertID ) ).ToString("00000") ) | Remove-InvalidFileNameChars ).xml"
    Write-Progress -Activity "Exporting Alerts" -Status "Saving to '$AlertFile'"
    $AlertBody.Save(( Join-Path -Path $OutputPath -ChildPath $AlertFile))
}
Write-Progress -Activity "Exporting Alerts" -Completed
