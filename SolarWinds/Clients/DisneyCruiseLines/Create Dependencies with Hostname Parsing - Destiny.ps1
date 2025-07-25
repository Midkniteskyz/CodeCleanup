# ============================================================================
# Script: Create Dependencies from Parent Nodes to Child Groups
# Author: Ryan Woolsey
# Date: 2025-07-09
# Description: Automates the creation of dependencies between distribution nodes
#              and their corresponding access groups in SolarWinds Orion
# ============================================================================

# Requires -Version 5.1
#Requires -Module SwisPowerShell

# ============================================================================
# FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Writes timestamped log messages with color formatting
.PARAMETER Message
    The message to write
.PARAMETER Level
    Log level (INFO, WARNING, ERROR)
.PARAMETER Color
    Console color for the message
#>
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR")]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if ($Color -ne "White") {
        Write-Host $logMessage -ForegroundColor $Color
    } else {
        Write-Host $logMessage
    }
}

<#
.SYNOPSIS
    Validates that required parameters are not null or empty
.PARAMETER Parameters
    Hashtable of parameter names and values to validate
#>
function Test-RequiredParameters {
    param([hashtable]$Parameters)
    
    foreach ($param in $Parameters.GetEnumerator()) {
        if ([string]::IsNullOrWhiteSpace($param.Value)) {
            throw "Required parameter '$($param.Key)' is null or empty"
        }
    }
}

<#
.SYNOPSIS
    Extracts site code from parent node name using regex
.PARAMETER NodeName
    The parent node name to parse
.RETURNS
    Site code if found, null otherwise
#>
function Get-SiteCodeFromNodeName {
    param([string]$NodeName)
    
    # Match pattern like: PREFIX-301IT-SUFFIX or PREFIX-301-SUFFIX
    if ($NodeName -match '-(?<site>[0-9]{3})(?:IT)?-') {
        return $matches.site
    }
    
    return $null
}

<#
.SYNOPSIS
    Creates a dependency object in SolarWinds Orion
.PARAMETER Swis
    SolarWinds Information Service connection object
.PARAMETER Properties
    Hashtable containing dependency properties
.PARAMETER WhatIf
    If true, only shows what would be created without making changes
#>
function New-OrionDependency {
    param(
        [object]$Swis,
        [hashtable]$Properties,
        [bool]$WhatIf = $false
    )
    
    if ($WhatIf) {
        Write-Host "[DRY RUN] Would create dependency: $($Properties.Name)" -ForegroundColor Cyan
        Write-Host "           Parent: $($Properties.ParentUri)" -ForegroundColor DarkGray
        Write-Host "           Child:  $($Properties.ChildUri)" -ForegroundColor DarkGray
        Write-Host "           Description: $($Properties.Description)" -ForegroundColor DarkGray
        return $true
    } else {
        try {
            New-SwisObject $Swis -EntityType 'Orion.Dependencies' -Properties $Properties
            Write-Log "✅ Created dependency: $($Properties.Name)" "INFO" "Green"
            return $true
        } catch {
            Write-Log "❌ Failed to create dependency '$($Properties.Name)': $($_.Exception.Message)" "ERROR" "Red"
            return $false
        }
    }
}

# ============================================================================
# CONFIGURATION SECTION
# ============================================================================

# SolarWinds connection parameters
# TODO: Consider using secure credential storage instead of plain text passwords
$OrionServer = "DCLDESSOLARW01"              # SolarWinds server hostname or IP
$Username = "Loop1"                          # SolarWinds username
$Password = "30DayPassword!"                 # SolarWinds password (consider using SecureString)

# File paths and settings
$ParentListPath = "D:\Installs\Script\parentdependencies.txt"  # Path to parent node names file
$WhatIf = $true                              # Set to $false to actually create dependencies

# Dependency naming patterns
$ChildGroupNamePattern = "{0} - Access"      # Pattern for child group names (site code + " - Access")
$DependencyNamePattern = "Distro -> Access - {0}"  # Pattern for dependency names

# ============================================================================
# PARAMETER VALIDATION
# ============================================================================

Write-Log "Starting SolarWinds Dependency Creation Script" "INFO" "Yellow"

# Validate required parameters
try {
    Test-RequiredParameters @{
        'OrionServer' = $OrionServer
        'Username' = $Username
        'Password' = $Password
        'ParentListPath' = $ParentListPath
    }
    Write-Log "Parameter validation passed" "INFO" "Green"
} catch {
    Write-Log "Parameter validation failed: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}

# Validate file existence
if (-not (Test-Path $ParentListPath)) {
    Write-Log "Parent list file not found: $ParentListPath" "ERROR" "Red"
    exit 1
}

# ============================================================================
# SOLARWINDS CONNECTION
# ============================================================================

# Import and verify SolarWinds PowerShell module
try {
    Import-Module SwisPowerShell -ErrorAction Stop
    Write-Log "SolarWinds PowerShell module loaded successfully" "INFO" "Green"
} catch {
    Write-Log "Failed to load SolarWinds PowerShell module. Please ensure OrionSDK is installed." "ERROR" "Red"
    exit 1
}

# Connect to SolarWinds Information Service (SWIS)
try {
    Write-Log "Connecting to SolarWinds server: $OrionServer" "INFO" "Yellow"
    $swis = Connect-Swis -host $OrionServer -UserName $Username -Password $Password
    Write-Log "Successfully connected to SolarWinds" "INFO" "Green"
} catch {
    Write-Log "Failed to connect to SolarWinds: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}

# ============================================================================
# DATA LOADING AND PREPARATION
# ============================================================================

# Load parent node names from file, filtering out empty lines and whitespace
Write-Log "Loading parent node names from: $ParentListPath" "INFO" "Yellow"
try {
    $parentNames = Get-Content $ParentListPath -ErrorAction Stop | 
                   Where-Object { $_ -and $_.Trim() -ne "" } |
                   ForEach-Object { $_.Trim() }
    
    Write-Log "Loaded $($parentNames.Count) parent node names" "INFO" "Green"
} catch {
    Write-Log "Failed to load parent list file: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}

# Validate we have parent names to process
if ($parentNames.Count -eq 0) {
    Write-Log "No parent node names found in file. Exiting." "WARNING" "Yellow"
    exit 0
}

# Load all container members from SolarWinds for efficient lookup
Write-Log "Loading container members from SolarWinds..." "INFO" "Yellow"
try {
    $containerMembers = Get-SwisData $Swis @"
SELECT DISTINCT
    MemberPrimaryID,
    FullName,
    MemberEntityType,
    MemberUri
FROM Orion.ContainerMembers
WHERE FullName IS NOT NULL
ORDER BY FullName
"@ | ForEach-Object {
        [PSCustomObject]@{
            Name          = $_.FullName
            EntityType    = $_.MemberEntityType
            Uri           = $_.MemberUri
            NetObjectID   = $_.MemberPrimaryID
        }
    }
    
    Write-Log "Loaded $($containerMembers.Count) container members" "INFO" "Green"
} catch {
    Write-Log "Failed to load container members: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}

# Create lookup hashtable for fast name-based searches
# Using -AsString to ensure string keys for reliable lookups
$containerByName = $containerMembers | Group-Object -Property Name -AsHashTable -AsString

# ============================================================================
# DEPENDENCY CREATION PROCESS
# ============================================================================

Write-Log "Starting dependency creation process..." "INFO" "Yellow"

# Initialize counters for reporting
$processedCount = 0
$successCount = 0
$errorCount = 0

foreach ($parentNodeName in $parentNames) {
    $processedCount++
    Write-Log "Processing parent node [$processedCount/$($parentNames.Count)]: $parentNodeName" "INFO" "White"
    
    # Extract site code from parent node name
    $siteCode = Get-SiteCodeFromNodeName -NodeName $parentNodeName
    
    if (-not $siteCode) {
        Write-Log "Could not extract site code from parent node name: $parentNodeName" "WARNING" "Yellow"
        $errorCount++
        continue
    }
    
    Write-Log "Extracted site code: $siteCode" "INFO" "DarkGray"
    
    # Generate child group name and dependency name based on site code
    $childGroupName = $ChildGroupNamePattern -f $siteCode
    $dependencyName = $DependencyNamePattern -f $siteCode
    
    # Find parent node in container members (select first match to avoid duplicates)
    $parentMatch = $containerMembers | Where-Object { $_.Name -eq $parentNodeName } | Select-Object -First 1
    
    if (-not $parentMatch) {
        Write-Log "Parent node not found in container members: $parentNodeName" "WARNING" "Yellow"
        $errorCount++
        continue
    }
    
    Write-Log "Found parent node: $($parentMatch.Name) (Type: $($parentMatch.EntityType))" "INFO" "DarkGray"
    
    # Find child group in container members using hashtable lookup for performance
    $childMatch = $containerByName[$childGroupName]
    
    # Handle case where hashtable returns array of duplicates
    if ($childMatch -is [Array]) {
        $childMatch = $childMatch[0]
        Write-Log "Multiple child groups found for '$childGroupName', using first match" "WARNING" "Yellow"
    }
    
    if (-not $childMatch) {
        Write-Log "Child group not found in container members: $childGroupName" "WARNING" "Yellow"
        $errorCount++
        continue
    }
    
    Write-Log "Found child group: $($childMatch.Name) (Type: $($childMatch.EntityType))" "INFO" "DarkGray"
    
    # Prepare dependency properties
    $dependencyProperties = @{
        Name              = $dependencyName
        ParentUri         = $parentMatch.Uri
        ParentEntityType  = $parentMatch.EntityType
        ParentNetObjectID = $parentMatch.NetObjectID
        ChildUri          = $childMatch.Uri
        ChildEntityType   = $childMatch.EntityType
        ChildNetObjectID  = $childMatch.NetObjectID
        Description       = "Automated dependency from distribution node '$($parentMatch.Name)' to access group '$($childMatch.Name)' (Site: $siteCode)"
    }
    
    # Create the dependency
    $success = New-OrionDependency -Swis $swis -Properties $dependencyProperties -WhatIf $WhatIf
    
    if ($success) {
        $successCount++
    } else {
        $errorCount++
    }
    
    # Add small delay to avoid overwhelming the SolarWinds API
    Start-Sleep -Milliseconds 100
}

# ============================================================================
# SUMMARY REPORT
# ============================================================================

Write-Log "=================================" "INFO" "Yellow"
Write-Log "DEPENDENCY CREATION SUMMARY" "INFO" "Yellow"
Write-Log "=================================" "INFO" "Yellow"
Write-Log "Total parent nodes processed: $processedCount" "INFO" "White"
Write-Log "Dependencies created successfully: $successCount" "INFO" "Green"
Write-Log "Errors encountered: $errorCount" "INFO" $(if ($errorCount -gt 0) { "Red" } else { "Green" })

if ($WhatIf) {
    Write-Log "*** DRY RUN MODE - No actual changes were made ***" "INFO" "Cyan"
    Write-Log "Set `$WhatIf = `$false to create dependencies" "INFO" "Cyan"
}

Write-Log "Script execution completed" "INFO" "Green"

# Exit with appropriate code
exit $(if ($errorCount -gt 0) { 1 } else { 0 })