# ============================================================================
# Script: Create Dependencies from Parent Nodes to Child Groups
# Author: Ryan Woolsey
# Date: 2025-07-09
# ============================================================================

# Import required modules
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

# SolarWinds connection parameters
# Update these values to match your environment
$OrionServer = "DCLADVSOLARW01"    # SolarWinds server OrionServer or IP
$username = "Loop1"             # SolarWinds username
$password = "30DayPassword!"    # SolarWinds password

$ParentListPath =   # Path to the text file with parent node names
$WhatIf = $false           # Optional switch for dry run mode

# ============================================================================
# MAIN SCRIPT EXECUTION
# ============================================================================

# Connect to SolarWinds Information Service (SWIS)
try {
    Write-Log "Connecting to SolarWinds server: $OrionServer" "INFO" "Yellow"
    $swis = Connect-Swis -host $OrionServer -UserName $username -Password $password
    Write-Log "Successfully connected to SolarWinds" "INFO" "Green"
} catch {
    Write-Log "Failed to connect to SolarWinds: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}

# Load parent node names from file
$parentNames = Get-Content $ParentListPath | Where-Object { $_ -and $_.Trim() -ne "" }

# Load all relevant container members once
$containerMembers = Get-SwisData $Swis @"
SELECT
  MemberPrimaryID,
  FullName,
  MemberEntityType,
  MemberUri
FROM Orion.ContainerMembers
"@ | ForEach-Object {
    [PSCustomObject]@{
        Name          = $_.FullName
        EntityType    = $_.MemberEntityType
        Uri           = $_.MemberUri
        NetObjectID   = $_.MemberPrimaryID
    }
}

# Build a lookup by name for fast matching
$containerByName = $containerMembers | Group-Object -Property Name -AsHashTable -AsString

foreach ($parent in $parentNames) {
    # Extract site code like 612C1 and convert to 612C.1
    if ($parent -match '-(?<site>[0-9]{3}[A-Z][0-9])-') {
        $rawSite = $matches.site
        $parsedSite = $rawSite.Insert($rawSite.Length - 1, ".")  # 612C1 → 612C.1
        $childGroupName = "$parsedSite - Access"
        $dependencyName = "Distro -> Access - $parsedSite"

        # Match parent
        $parentMatch = $containerMembers | Where-Object {
            $_.Name -eq $parent
        }

        if (-not $parentMatch) {
            Write-Warning "No match found in ContainerMembers for parent node: $parent"
            continue
        }

        # Match child
        $childMatch = $containerByName[$childGroupName]

        if (-not $childMatch) {
            Write-Warning "No matching child group found for parsed site: $childGroupName"
            continue
        }

        $props = @{
            Name              = $dependencyName
            ParentUri         = $parentMatch.Uri
            ParentEntityType  = $parentMatch.EntityType
            ParentNetObjectID = $parentMatch.NetObjectID
            ChildUri          = $childMatch.Uri
            ChildEntityType   = $childMatch.EntityType
            ChildNetObjectID  = $childMatch.NetObjectID
            Description       = "Automated dependency from distro node '$($parentMatch.Name)' to access group '$($childMatch.Name)'"
        }

        if ($WhatIf) {
            Write-Host "[DRY RUN] Would create dependency: $($props.Name)" -ForegroundColor Cyan
            Write-Host "           ParentUri: $($props.ParentUri)" -ForegroundColor DarkGray
            Write-Host "           ChildUri:  $($props.ChildUri)" -ForegroundColor DarkGray
        } else {
            try {
                New-SwisObject $Swis -EntityType 'Orion.Dependencies' -Properties $props
                Write-Host "✅ Created dependency: $($props.Name)" -ForegroundColor Green
            } catch {
                Write-Warning "❌ Failed to create dependency for $parsedSite — $_"
            }
        }
    } else {
        Write-Warning "Could not parse site from parent node name: $parent"
    }
}