# ============================================================================
# SolarWinds Group Creation Script
# ============================================================================
#
# Author: Ryan Woolsey
# Date: 7/9/2025
# Version: 1.1
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

$hostname = "DCLADVSOLARW01"
$username = "Loop1"
$password = "30DayPassword!"

$dryRun = $true
$logFile = "SolarWinds_Update_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [ConsoleColor]$Color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $Color
    Add-Content -Path $logFile -Value $logEntry
}

function New-SwisDynamicGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [object]$SwisConnection,
        [Parameter(Mandatory)] [string]$GroupName,
        [string]$Description = "Group created by script.",
        [ValidateSet(0, 1, 2)] [int]$RollupMode = 0,
        [int]$RefreshInterval = 60,
        [bool]$PollingEnabled = $true,
        [Parameter(Mandatory)] [array]$Members
    )
    foreach ($member in $Members) {
        if (-not ($member.ContainsKey("Name") -and $member.ContainsKey("Definition"))) {
            throw "Each member must have 'Name' and 'Definition' keys."
        }
    }
    $xmlContent = @(
        "<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>"
        $Members | ForEach-Object {
            "<MemberDefinitionInfo><Name>$($_.Name)</Name><Definition>$($_.Definition)</Definition></MemberDefinitionInfo>"
        }
        "</ArrayOfMemberDefinitionInfo>"
    ) -join "`n"
    $xmlMembers = [xml]$xmlContent
    try {
        $groupId = (Invoke-SwisVerb $SwisConnection "Orion.Container" "CreateContainer" @(
            $GroupName, "Core", $RefreshInterval, $RollupMode,
            $Description, $PollingEnabled.ToString().ToLower(), $xmlMembers.DocumentElement
        )).InnerText
        Write-Host "Group '$GroupName' created successfully with ID: $groupId"
        return $groupId
    } catch {
        Write-Error "Failed to create group: $_"
    }
}

function Add-SwisSubGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [object]$SwisConnection,
        [Parameter(Mandatory)] [string]$SubGroupName,
        [Parameter(Mandatory)] [int]$ParentGroupId,
        [array]$Members,
        [string]$Description = "Subgroup created by script.",
        [ValidateSet(0, 1, 2)] [int]$RollupMode = 0,
        [int]$RefreshInterval = 60,
        [bool]$PollingEnabled = $true
    )
    foreach ($member in $Members) {
        if (-not ($member.ContainsKey("Name") -and $member.ContainsKey("Definition"))) {
            throw "Each member must have 'Name' and 'Definition' keys."
        }
    }
    try {
        $xmlContent = @(
            "<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>"
            $Members | ForEach-Object {
                "<MemberDefinitionInfo><Name>$($_.Name)</Name><Definition>$($_.Definition)</Definition></MemberDefinitionInfo>"
            }
            "</ArrayOfMemberDefinitionInfo>"
        ) -join "`n"
        $xmlMembers = [xml]$xmlContent
        $subGroupId = (Invoke-SwisVerb $SwisConnection "Orion.Container" "CreateContainer" @(
            $SubGroupName, "Core", $RefreshInterval, $RollupMode,
            $Description, $PollingEnabled.ToString().ToLower(), $xmlMembers.DocumentElement
        )).InnerText
        Write-Host "Subgroup '$SubGroupName' created with ID: $subGroupId" -ForegroundColor Green
        $subGroupUri = Get-SwisData $SwisConnection "SELECT Uri FROM Orion.Container WHERE ContainerID=@id" @{ id = $subGroupId }
        Invoke-SwisVerb $SwisConnection "Orion.Container" "AddDefinition" @(
            $ParentGroupId,
            ([xml]"<MemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'><Name>$SubGroupName</Name><Definition>$subGroupUri</Definition></MemberDefinitionInfo>").DocumentElement
        ) | Out-Null
        Write-Host "Subgroup '$SubGroupName' added to parent group ID $ParentGroupId" -ForegroundColor Cyan
        return $subGroupId
    } catch {
        Write-Error "Failed to create or add subgroup: $_"
        return $null
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Log "Starting SolarWinds Group Creation Script" "INFO" "Cyan"
Write-Log "Dry Run Mode: $dryRun" "INFO" "Yellow"

try {
    Write-Log "Connecting to SolarWinds server: $hostname" "INFO" "Yellow"
    $swis = Connect-Swis -host $hostname -UserName $username -Password $password
    Write-Log "Successfully connected to SolarWinds" "INFO" "Green"
} catch {
    Write-Log "Failed to connect to SolarWinds: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}

$rootGroup = "Test parent"
$subGroups = @("subtest1", "subtest2")
$processedCount = 0; $updatedCount = 0; $errorCount = 0

$rootGroupId = New-SwisDynamicGroup -SwisConnection $swis -GroupName $rootGroup -Description "Auto-generated parent group" -RollupMode 0 -RefreshInterval 60 -PollingEnabled $true -Members @(@{ Name = "Cisco Devices"; Definition = "filter:/Orion.Nodes[Vendor='Cisco']" })

foreach ($group in $subGroups) {
    $processedCount++
    $groupName = "$group - $rootGroup"
    try {
        Write-Log "Processing group [$processedCount/$($subGroups.Count)]: $group" "INFO" "Cyan"
        Write-Log "  Creating Group: $groupName" "INFO" "Yellow"

        if (-not $dryRun) {
            $subGroupMembers = @( @{ Name = "Only Cisco Up"; Definition = "filter:/Orion.Nodes[Vendor='Cisco' AND Status=1]" })
            $subGroupId = Add-SwisSubGroup -SwisConnection $swis -SubGroupName $groupName -ParentGroupId $rootGroupId -Members $subGroupMembers -Description "Auto-subgroup with filtered definitions" -PollingEnabled $true
            Write-Log "  Successfully created group '$groupName' with ID: $subGroupId" "INFO" "Green"
            $updatedCount++
        } else {
            Write-Log "  [DRY RUN] Would create group: $groupName" "INFO" "Magenta"
        }
        Write-Log "" "INFO" "White"
    } catch {
        Write-Log "Error processing group $group : $($_.Exception.Message)" "ERROR" "Red"
        $errorCount++
    }
}

Write-Log "============================================================================" "INFO" "Cyan"
Write-Log "EXECUTION SUMMARY" "INFO" "Cyan"
Write-Log "============================================================================" "INFO" "Cyan"
Write-Log "Total groups processed: $processedCount" "INFO" "White"
Write-Log "Groups created: $updatedCount" "INFO" "Green"
Write-Log "Errors encountered: $errorCount" "INFO" $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Log "Dry run mode: $dryRun" "INFO" "Yellow"
Write-Log "Log file: $logFile" "INFO" "White"
if ($dryRun) {
    Write-Log "This was a dry run. No actual changes were made." "INFO" "Yellow"
    Write-Log "To apply changes, set `$dryRun = `$false at the top of the script." "INFO" "Yellow"
}
Write-Log "Script execution completed" "INFO" "Cyan"

if ($swis -and $swis.GetType().GetMethod("Dispose")) {
    $swis.Dispose()
    Write-Log "Disconnected from SolarWinds" "INFO" "Green"
}
