# ============================================================================
# SolarWinds Node Custom Properties Update Script
# ============================================================================
# 
# Purpose: This script connects to SolarWinds Orion and updates custom properties
#          for nodes based on parsed caption information. It extracts department
#          and RDP (Remote Desktop Protocol) information from node captions.
#
# Author: Ryan Woolsey
# Date: 7/8/2025
# Version: 2.0
# 
# Prerequisites:
# - SolarWinds PowerShell module (OrionSDK) must be installed
# - User must have appropriate permissions in SolarWinds
# - Network connectivity to SolarWinds server
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
$hostname = "DCLADVSOLARW01"    # SolarWinds server hostname or IP
$username = "Loop1"             # SolarWinds username
$password = "30DayPassword!"    # SolarWinds password

# Script execution parameters
$dryRun = $true                 # Set to $false to actually update properties
$logFile = "SolarWinds_Update_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# ============================================================================
# LOGGING FUNCTION
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [ConsoleColor]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with color
    Write-Host $logEntry -ForegroundColor $Color
    
    # Write to log file
    Add-Content -Path $logFile -Value $logEntry
}

# ============================================================================
# MAIN SCRIPT EXECUTION
# ============================================================================

Write-Log "Starting SolarWinds Node Custom Properties Update Script" "INFO" "Cyan"
Write-Log "Dry Run Mode: $dryRun" "INFO" "Yellow"

# Connect to SolarWinds Information Service (SWIS)
try {
    Write-Log "Connecting to SolarWinds server: $hostname" "INFO" "Yellow"
    $swis = Connect-Swis -host $hostname -UserName $username -Password $password
    Write-Log "Successfully connected to SolarWinds" "INFO" "Green"
} catch {
    Write-Log "Failed to connect to SolarWinds: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}

# ============================================================================
# SWQL QUERY DEFINITION
# ============================================================================

# This complex SWQL query does the following:
# 1. Selects nodes from the Orion.Nodes table
# 2. Parses the caption to extract RDP information by:
#    - Removing various prefixes (eordcl-adv-dst-, eordcl-adv-ra-, etc.)
#    - Removing domain suffixes (.dcl.wdpr.disney.com)
#    - Taking first 5 characters and applying replacements
#    - Converting UC->DC, IT->DC, AD->DC, DB->DC
#    - Adding periods after P and S
# 3. Determines department based on caption patterns:
#    - If caption contains '-mto-' -> 'MTO'
#    - If caption contains '-ent-' -> 'Entertainment'
#    - Otherwise -> 'IT'
# 4. Excludes specific machine types and includes only captions with number patterns

$swqlQuery = @"
SELECT
    n.ip_address,
    n.caption,
    -- Parse RDP information from caption
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            SubString(
                                REPLACE(
                                    CASE
                                        -- Remove various Disney-specific prefixes
                                        WHEN n.caption LIKE '%eordcl-adv-dst-%' THEN REPLACE(n.Caption, 'eordcl-adv-dst-', '')
                                        WHEN n.caption LIKE '%eordcl-adv-ra-%' THEN REPLACE(n.Caption, 'eordcl-adv-ra-', '')
                                        WHEN n.caption LIKE '%eordcl-adv-dc-%' THEN REPLACE(n.Caption, 'eordcl-adv-dc-', '')
                                        WHEN n.caption LIKE '%eordcl-adv-c-%' THEN REPLACE(n.Caption, 'eordcl-adv-c-', '')
                                        WHEN n.caption LIKE '%eordcl-adv-%' THEN REPLACE(n.Caption, 'eordcl-adv-', '')
                                        WHEN n.caption LIKE '%dcladv%' THEN REPLACE(n.Caption, 'dcladv', '')
                                        ELSE caption
                                    END,
                                    '.dcl.wdpr.disney.com',  -- Remove domain suffix
                                    ''
                                ),
                                1,
                                5  -- Take first 5 characters
                            ),
                            'UC', 'DC'  -- Replace UC with DC
                        ),
                        'IT', 'DC'      -- Replace IT with DC
                    ),
                    'AD', 'DC'          -- Replace AD with DC
                ),
                'DB', 'DC'              -- Replace DB with DC
            ),
            'P', 'P.'                   -- Add period after P
        ),
        'S', 'S.'                       -- Add period after S
    ) AS [Parsed_RDP],
    n.CustomProperties.RDP,             -- Current RDP value
    -- Parse department information from caption
    CASE
        WHEN n.caption LIKE '%-mto-%' THEN 'MTO'
        WHEN n.caption LIKE '%-ent-%' THEN 'Entertainment'
        ELSE 'IT'
    END AS [Parsed_Department],
    n.CustomProperties.Department,      -- Current Department value
    n.NodeId                           -- Node ID for updates
FROM
    orion.nodes AS n
WHERE
    n.MachineType != 'Cisco Catalyst C9200CX-12P-2X2G'    -- Exclude specific device types
    AND caption LIKE '%[0-9][0-9][0-9][a-zA-Z]%'          -- Include only captions with 3 digits + letter pattern
ORDER BY
    n.caption DESC
"@

# ============================================================================
# EXECUTE QUERY AND PROCESS RESULTS
# ============================================================================

try {
    Write-Log "Executing SWQL query to retrieve node information" "INFO" "Yellow"
    $swisNodeQuery = Get-SwisData -SwisConnection $swis -Query $swqlQuery
    Write-Log "Query executed successfully. Found $($swisNodeQuery.Count) nodes to process" "INFO" "Green"
} catch {
    Write-Log "Failed to execute SWQL query: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}

# Initialize counters for reporting
$processedCount = 0
$updatedCount = 0
$errorCount = 0

# Process each node returned by the query
foreach ($node in $swisNodeQuery) {
    $processedCount++
    
    try {
        # Extract node information
        $nodeId = $node.NodeID
        $caption = $node.Caption
        $currentRDP = $node.RDP
        $currentDepartment = $node.Department
        $newRDP = $node.Parsed_RDP
        $newDepartment = $node.Parsed_Department
        
        Write-Log "Processing node [$processedCount/$($swisNodeQuery.Count)]: $caption" "INFO" "Cyan"
        
        # Check if updates are needed
        $needsUpdate = $false
        $updateDetails = @()
        
        if ($currentRDP -ne $newRDP) {
            $needsUpdate = $true
            $updateDetails += "RDP: '$currentRDP' -> '$newRDP'"
        }
        
        if ($currentDepartment -ne $newDepartment) {
            $needsUpdate = $true
            $updateDetails += "Department: '$currentDepartment' -> '$newDepartment'"
        }
        
        if ($needsUpdate) {
            # Log the proposed changes
            Write-Log "  Updates needed:" "INFO" "Yellow"
            foreach ($detail in $updateDetails) {
                Write-Log "    $detail" "INFO" "Green"
            }
            
            # Prepare custom property values
            $customProps = @{
                RDP = $newRDP
                Department = $newDepartment
            }
            
            # Build the URI for the custom properties
            $uri = "swis://localhost/Orion/Orion.Nodes/NodeID=$($nodeId)/CustomProperties"
            
            if (-not $dryRun) {
                # Actually update the properties
                try {
                    Set-SwisObject $swis -Uri $uri -Properties $customProps
                    Write-Log "  Successfully updated custom properties" "INFO" "Green"
                    $updatedCount++
                } catch {
                    Write-Log "  Failed to update custom properties: $($_.Exception.Message)" "ERROR" "Red"
                    $errorCount++
                }
            } else {
                Write-Log "  [DRY RUN] Would update custom properties" "INFO" "Magenta"
            }
        } else {
            Write-Log "  No updates needed" "INFO" "Gray"
        }
        
        # Add spacing between nodes for readability
        Write-Log "" "INFO" "White"
        
    } catch {
        Write-Log "Error processing node $caption : $($_.Exception.Message)" "ERROR" "Red"
        $errorCount++
    }
}

# ============================================================================
# SUMMARY REPORT
# ============================================================================

Write-Log "============================================================================" "INFO" "Cyan"
Write-Log "EXECUTION SUMMARY" "INFO" "Cyan"
Write-Log "============================================================================" "INFO" "Cyan"
Write-Log "Total nodes processed: $processedCount" "INFO" "White"
Write-Log "Nodes updated: $updatedCount" "INFO" "Green"
Write-Log "Errors encountered: $errorCount" "INFO" $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Log "Dry run mode: $dryRun" "INFO" "Yellow"
Write-Log "Log file: $logFile" "INFO" "White"

if ($dryRun) {
    Write-Log "" "INFO" "White"
    Write-Log "This was a dry run. No actual changes were made." "INFO" "Yellow"
    Write-Log "To apply changes, set `$dryRun = `$false at the top of the script." "INFO" "Yellow"
}

Write-Log "Script execution completed" "INFO" "Cyan"

# ============================================================================
# CLEANUP
# ============================================================================

# Disconnect from SolarWinds (if connection object supports it)
if ($swis -and $swis.GetType().GetMethod("Dispose")) {
    $swis.Dispose()
    Write-Log "Disconnected from SolarWinds" "INFO" "Green"
}