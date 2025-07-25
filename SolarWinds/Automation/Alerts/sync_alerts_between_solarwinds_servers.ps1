$ErrorActionPreference = 'Stop'

# Ensure SwisPowerShell module is loaded
if (!(Get-InstalledModule | Where-Object { $_.Name -eq "SwisPowerShell" })) {
    Import-Module SwisPowerShell
}

# Connect to the source SolarWinds server
$swissrc = Connect-Swis -Hostname 192.168.25.30 -Username "l1seng\ashah" -Password "XXX"

# TODO: Connect to the destination SolarWinds server if comparing against another instance
# $swisdst = Connect-Swis -Hostname "other.server" -Username "..." -Password "..."

# Define the export output file path
$exportedFilePath = "ExportedAlerts.csv"

# Get all enabled alerts from the source
$AlertIDsSRC = Get-SwisData -SwisConnection $swissrc -Query @"
SELECT Name, AlertID 
FROM Orion.AlertConfigurations 
WHERE Enabled = 1
"@

$count = 0

foreach ($AlertID in $AlertIDsSRC) {
    # Currently checking against source again, not destination!
    # For true migration comparison, switch this to check $swisdst
    $AlertExists = Get-SwisData -SwisConnection $swissrc -Query "SELECT Name FROM Orion.AlertConfigurations WHERE Name = '$($AlertID.Name)'"

    if (-not $AlertExists) {
        $count++
        Write-Output ("Alert not in DST. Exporting Alert: {0:D4} {1}" -f $count, $AlertID.Name)

        $ExportedAlertSRC = Invoke-SwisVerb $swissrc Orion.AlertConfigurations Export $AlertID.AlertID

        # Convert returned XML to PowerShell object
        $AlertObject = [xml]$ExportedAlertSRC.InnerText

        # Export to CSV — but note: XML objects flatten poorly to CSV
        $AlertObject | Export-Csv -Path $exportedFilePath -Append -NoTypeInformation
    } else {
        Write-Output "Alert in DST. Skipping: $($AlertID.Name)"
    }
}

Write-Output "Total Alerts: $($AlertIDsSRC.Count)"
Write-Output "Missing in DST: $count"
Write-Output "Exported to: $exportedFilePath"
