# ====================================================================
# SolarWinds Multi-Instance Caption Cleanup Script
# ====================================================================
# Author: Ryan Woolsey
# Date: 7/15/2025
# Version: 2.0
#
# Features:
# - Supports multiple SolarWinds instances
# - Converts node captions to uppercase and strips FQDN
# - Optional: Replace substrings in hostname (e.g., remove 'old', add 'new')
# - Dry-run support to preview changes
# ====================================================================


# List of SolarWinds server hostnames/IPs
$OrionServers = ("localhost")

$Username = "Loop1"
$Password = "30DayPassword!"

# Set to $false to apply changes
$DryRun = $true

# Example: @{".corp.local" = ""; "-old" = "-new"}
$ReplaceMap = @{"" = "";}

# Load SolarWinds module
try {
    Import-Module SwisPowerShell -ErrorAction Stop
    Write-Host "SolarWinds PowerShell module loaded successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to load SolarWinds PowerShell module. Exiting."
    exit 1
}

# Function to clean up caption
function Get-CleanCaption {
    param (
        [string]$OriginalCaption,
        [hashtable]$ReplaceMap
    )
    
    $base = $OriginalCaption.Split('.')[0].ToUpper()
    
    if ($ReplaceMap) {
        foreach ($key in $ReplaceMap.Keys) {
            $base = $base -replace [regex]::Escape($key), $ReplaceMap[$key]
        }
    }

    return $base
}

# Iterate through each SolarWinds instance
foreach ($Server in $OrionServers) {
    Write-Host "`n==== Connecting to $Server ====" -ForegroundColor Cyan

    try {
        $swis = Connect-Swis -Hostname $Server -Username $Username -Password $Password
    } catch {
        Write-Warning "Could not connect to $Server. Skipping."
        continue
    }

    $query = @"
        SELECT
            Nodes.Caption,
            Nodes.URI
        FROM Orion.Nodes AS Nodes
"@

    try {
        $nodes = Get-SwisData -SwisConnection $swis -Query $query
    } catch {
        Write-Warning "Query failed for $Server. Skipping."
        continue
    }

    foreach ($node in $nodes) {
        $original = $node.Caption

        # Skip captions that are IP addresses (e.g., 192.168.1.1)
        if ($original -match '^\d{1,3}(\.\d{1,3}){3}$') {
            Write-Host "Skipping IP address caption: $original" -ForegroundColor Cyan
            continue
        }

        $cleanCaption = Get-CleanCaption -OriginalCaption $node.Caption -ReplaceMap $ReplaceMap

        if ($node.Caption -ceq $cleanCaption) {
            continue
        }

        Write-Host "[$Server] Renaming node '$($node.Caption)' => '$cleanCaption'" -ForegroundColor Yellow

        if (-not $DryRun) {
            try {
                Set-SwisObject -SwisConnection $swis -Uri $node.URI -Properties @{ "Caption" = $cleanCaption }
                Write-Host "    ✔ Updated." -ForegroundColor Green
            } catch {
                Write-Warning "    ✖ Failed to update node: $($_.Exception.Message)"
            }
        }
    }
}
