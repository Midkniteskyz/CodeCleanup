$ErrorActionPreference = 'Stop'

# Ensure SwisPowerShell module is loaded
if (-not (Get-Module -ListAvailable -Name "SwisPowerShell")) {
    Import-Module SwisPowerShell
}

# Prompt for credentials
$sourceCred = Get-Credential -Message "Enter credentials for SOURCE SolarWinds"
#$destCred = Get-Credential -Message "Enter credentials for DESTINATION SolarWinds"

# Connect to source and destination servers
$swissrc = Connect-Swis -Hostname "Source" -Credential $sourceCred
$swisdst = Connect-Swis -Hostname "Destination" -Certificate #-Credential $destCred

# Query alerts on source - skip OOTB (AlertID < 1000)
$AlertIDsSRC = Get-SwisData -SwisConnection $swissrc -Query @"
SELECT Name, AlertID 
FROM Orion.AlertConfigurations 
WHERE Enabled = 1 AND Canned = 0
"@ | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.Name
        AlertID = $_.AlertID
    }
}

$count = 0
foreach ($alert in $AlertIDsSRC) {
    $query = "SELECT Name FROM Orion.AlertConfigurations WHERE Name = @name"
    $params = @{ name = $alert.Name }
    $AlertIDDST = Get-SwisData -SwisConnection $swisdst -Query $query -Parameters $params

    if (-not $AlertIDDST) {
        $count++
        Write-Output "[$($count.ToString("0000"))] Migrating Alert: $($alert.Name)"

        $exported = Invoke-SwisVerb -SwisConnection $swissrc -EntityName 'Orion.AlertConfigurations' -Verb 'Export' -Arguments $alert.AlertID
        $xmlText = $exported.InnerText

        $tempXmlFile = "ExportedAlert.xml"
        $xmlText | Out-File -FilePath $tempXmlFile -Encoding UTF8

        $alertXml = Get-Content -Path $tempXmlFile -Raw

        # Import into destination
        Invoke-SwisVerb -SwisConnection $swisdst -EntityName 'Orion.AlertConfigurations' -Verb 'Import' -Arguments @($alertXml)
    }
    else {
        Write-Output "Skipping (already exists): $($alert.Name)"
    }
}

Write-Output "Total Alerts in Source: $($AlertIDsSRC.Count)"
Write-Output "Migrated Alerts: $count"
