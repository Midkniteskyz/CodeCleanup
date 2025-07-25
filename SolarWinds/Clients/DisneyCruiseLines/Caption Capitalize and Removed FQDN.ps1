# ============================================================================
# SolarWinds Update Caption Script
# ============================================================================
#
# Author: Ryan Woolsey
# Date: 7/9/2025
# Version: 1.1
#
# Purpose: Capitalize the caption and remove the FQDN.
#
# Prerequisites:
# - SolarWinds PowerShell module (OrionSDK) must be installed
# - User must have appropriate permissions in SolarWinds
# - Network connectivity to SolarWinds server
# ============================================================================

# Import required module
try {
    Import-Module SwisPowerShell -ErrorAction Stop
    Write-Host "SolarWinds PowerShell module loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to load SolarWinds PowerShell module. Please ensure OrionSDK is installed."
    exit 1
}

# ============================================================================
# CONFIGURATION SECTION
# ============================================================================

$OrionServer = ""
$username = ""
$password = ""

$swis = Connect-Swis -Hostname $OrionServer -Username $Username -Password $Password

$query = "
    SELECT
        Nodes.Caption
        , Nodes.URI
    FROM Orion.Nodes AS Nodes
"

$nodes = Get-SwisData -SwisConnection $swis -Query $query

foreach ($node in $nodes) {

    $newName = $node.Caption.ToUpper().Replace(".DCL.WDPR.DISNEY.COM", "")
    
    $newName = $node.Caption.Split('.')[0].ToUpper()

    # skip over this node if it already has the right name
    if ($node.Caption -ceq $newName) {
        continue
    }

    Write-Output "Renaming node [$($node.Caption)] to [$newName]..."

    # uncomment the line below if you're seeing the output you expect above
    # Set-SwisObject -SwisConnection $swis -Uri $node.URI -Properties @{ "Caption" = $newName }
}
