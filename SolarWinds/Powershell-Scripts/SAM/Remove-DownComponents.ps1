param (
    [string]$Hostname = "localhost",
    [string]$Username = "admin",
    [string]$Password = "",
    [int]$TemplateId = 327,
    [switch]$WhatIf
)

# Connect to SWIS
$swis = Connect-Swis -Hostname $Hostname -UserName $Username -Password $Password

# Query Down components from the specified template
$query = @"
SELECT 
    a.Name AS ApplicationName,
    a.Node.Caption AS NodeCaption,
    c.Name AS ComponentName,
    c.Uri AS ComponentUri
FROM Orion.APM.Application AS a
JOIN a.Components AS c
WHERE a.ApplicationTemplateID = $TemplateId AND c.Status = 2
"@

$components = Get-SwisData $swis -Query $query

if ($components.Count -eq 0) {
    Write-Host "No down components found for template ID $TemplateId." -ForegroundColor Yellow
    return
}

foreach ($c in $components) {
    Write-Host "Removing" -NoNewline
    Write-Host " $($c.ComponentName) " -ForegroundColor Cyan -NoNewline
    Write-Host "from" -NoNewline
    Write-Host " $($c.NodeCaption)" -ForegroundColor Green

    if ($WhatIf) {
        Write-Host "[WhatIf] Skipping deletion of $($c.ComponentUri)" -ForegroundColor DarkGray
    }
    else {
        try {
            Remove-SwisObject -SwisConnection $swis -Uri $c.ComponentUri
            Write-Host "Successfully removed component." -ForegroundColor Green
        } catch {
            Write-Host "Failed to remove component: $_" -ForegroundColor Red
        }
    }
}
