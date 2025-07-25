$ErrorActionPreference = 'Stop'

# Load module
if (-not (Get-Module -ListAvailable -Name "SwisPowerShell")) {
    Import-Module SwisPowerShell
}

# Get credentials
$sourceCred = Get-Credential -Message "Enter credentials for SOURCE SolarWinds"
$destCred = Get-Credential -Message "Enter credentials for DESTINATION SolarWinds"

# Connect to servers
$swissrc = Connect-Swis -Hostname "192.168.25.30" -Credential $sourceCred
$swisdst = Connect-Swis -Hostname "192.168.25.25" -Credential $destCred

# Get list of custom reports from source
$reportList = Get-SwisData -SwisConnection $swissrc -Query @"
SELECT 
    name,
    description,
    limitationCategory,
    category,
    title,
    subtitle,
    definition
FROM Orion.Report
WHERE Owner IS NOT NULL
"@ | ForEach-Object {
    [PSCustomObject]@{
        name = $_.name
        description = $_.description
        limitationCategory = $_.limitationCategory
        category = $_.category
        title = $_.title
        subtitle = $_.subtitle
        definition = $_.definition
        isFavorite = "false"
        userName = "admin"
    }
}

$count = 0
foreach ($report in $reportList) {
    $checkQuery = "SELECT Title FROM Orion.Report WHERE Title = @title"
    $existingReport = Get-SwisData -SwisConnection $swisdst -Query $checkQuery -Parameters @{ title = $report.Title }

    if (-not $existingReport) {
        $count++
        Write-Output "[$($count.ToString("0000"))] Migrating Report: $($report.Title)"

        Invoke-SwisVerb -SwisConnection $swisdst -EntityName 'Orion.Report' -Verb 'CreateReport' -Arguments @(
        $report.name
        $report.description
        $report.limitationCategory
        $report.category
        $report.title
        $report.subtitle
        $report.definition
        "false"
        "admin"
        )
    }
    else {
        Write-Output "Skipping (already exists): $($report.Title)"
    }
}

Write-Output "Total Custom Reports in Source: $($reportList.Count)"
Write-Output "Migrated Reports: $count"
