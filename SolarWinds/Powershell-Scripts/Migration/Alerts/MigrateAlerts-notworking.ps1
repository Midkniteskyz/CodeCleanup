#Requires -Version 5.1
<#
.SYNOPSIS
    Migrates SolarWinds Orion alert configurations between two servers.

.DESCRIPTION
    This script connects to source and destination SolarWinds Orion instances and migrates
    enabled alert configurations that don't exist on the destination server.

.PARAMETER SourceHostname
    Hostname or IP address of the source SolarWinds server

.PARAMETER DestinationHostname
    Hostname or IP address of the destination SolarWinds server

.PARAMETER WhatIf
    Shows what would be migrated without actually performing the migration

.PARAMETER LogPath
    Path for log file (optional)

.EXAMPLE
    .\Migrate-SolarWindsAlerts.ps1 -SourceHostname "192.168.25.30" -DestinationHostname "192.168.25.25"

.EXAMPLE
    .\Migrate-SolarWindsAlerts.ps1 -SourceHostname "sw-prod" -DestinationHostname "sw-dr" -WhatIf
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceHostname,
    
    [Parameter(Mandatory = $true)]
    [string]$DestinationHostname,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = ".\SolarWinds-Migration-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

$ErrorActionPreference = 'Stop'

# Initialize logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Color coding for console output
    switch ($Level) {
        'Error'   { Write-Host $logEntry -ForegroundColor Red }
        'Warning' { Write-Host $logEntry -ForegroundColor Yellow }
        'Success' { Write-Host $logEntry -ForegroundColor Green }
        default   { Write-Host $logEntry }
    }
    
    # Write to log file
    Add-Content -Path $LogPath -Value $logEntry
}

# Function to safely escape SQL strings
function Get-SafeSqlString {
    param([string]$InputString)
    return $InputString -replace "'", "''"
}

# Function to ensure required module is available
function Initialize-SwisPowerShell {
    Write-Log "Checking for SwisPowerShell module..."
    
    try {
        # Check if module is already loaded
        if (!(Get-Module -Name "SwisPowerShell")) {
            # Check if module is installed
            if (!(Get-InstalledModule -Name "SwisPowerShell" -ErrorAction SilentlyContinue)) {
                throw "SwisPowerShell module is not installed. Please install it using: Install-Module -Name SwisPowerShell"
            }
            
            Import-Module SwisPowerShell -Force
            Write-Log "SwisPowerShell module imported successfully" -Level Success
        } else {
            Write-Log "SwisPowerShell module already loaded" -Level Success
        }
    }
    catch {
        Write-Log "Failed to initialize SwisPowerShell module: $($_.Exception.Message)" -Level Error
        throw
    }
}

# Function to establish secure connections
function Connect-SolarWindsServers {
    param(
        [string]$SourceHost,
        [string]$DestinationHost
    )
    
    Write-Log "Establishing secure connections to SolarWinds servers..."
    
    # Get credentials securely
    $credential = Get-Credential -Message "Enter credentials for SolarWinds servers"
    if (!$credential) {
        throw "Credentials are required to connect to SolarWinds servers"
    }
    
    try {
        Write-Log "Connecting to source server: $SourceHost"
        $sourceConnection = Connect-Swis -Hostname $SourceHost -Credential $credential
        
        Write-Log "Connecting to destination server: $DestinationHost"
        $destinationConnection = Connect-Swis -Hostname $DestinationHost -Certificate
        
        Write-Log "Successfully connected to both servers" -Level Success
        
        return @{
            Source = $sourceConnection
            Destination = $destinationConnection
        }
    }
    catch {
        Write-Log "Failed to connect to SolarWinds servers: $($_.Exception.Message)" -Level Error
        throw
    }
}

# Function to get alert configurations
function Get-AlertConfigurations {
    param(
        [object]$SwisConnection,
        [string]$ServerType
    )
    
    try {
        Write-Log "Retrieving alert configurations from $ServerType server..."
        
        if ($ServerType -eq "Source") {
            $query = "SELECT Name, AlertID FROM Orion.AlertConfigurations WHERE Enabled = 1 AND Canned = 0"
        } else {
            $query = "SELECT Name FROM Orion.AlertConfigurations"
        }
        
        $alerts = Get-SwisData -SwisConnection $SwisConnection -Query $query
        Write-Log "Retrieved $($alerts.Count) alert configurations from $ServerType server" -Level Success
        
        return $alerts
    }
    catch {
        Write-Log "Failed to retrieve alert configurations from $ServerType server: $($_.Exception.Message)" -Level Error
        throw
    }
}

# Function to check if alert exists on destination
function Test-AlertExists {
    param(
        [object]$DestinationConnection,
        [string]$AlertName,
        [array]$DestinationAlerts
    )
    
    # Use in-memory comparison for better performance
    return $DestinationAlerts -contains $AlertName
}

# Function to export and migrate alert
function Export-AndMigrateAlert {
    param(
        [object]$SourceConnection,
        [object]$DestinationConnection,
        [object]$AlertConfig,
        [int]$AlertNumber
    )
    
    $tempFile = $null
    try {
        Write-Log "Processing alert $($AlertNumber.ToString('0000')): $($AlertConfig.Name)"
        
        # Export alert from source
        $exportedAlert = Invoke-SwisVerb -SwisConnection $SourceConnection -EntityName "Orion.AlertConfigurations" -Verb "Export" -Arguments @($AlertConfig.AlertID)
        
        if (!$exportedAlert -or !$exportedAlert.InnerText) {
            throw "Failed to export alert or received empty content"
        }
        
        # Create temporary file for XML content
        $tempFile = [System.IO.Path]::GetTempFileName() + ".xml"
        Set-Content -Path $tempFile -Value $exportedAlert.InnerText -Encoding UTF8
        
        # Read XML content
        $alertXML = Get-Content -Path $tempFile -Raw
        
        if ($PSCmdlet.ShouldProcess($AlertConfig.Name, "Import Alert Configuration")) {
            # Import alert to destination
            Invoke-SwisVerb -SwisConnection $DestinationConnection -EntityName "Orion.AlertConfigurations" -Verb "Import" -Arguments @($alertXML)
            Write-Log "Successfully migrated alert: $($AlertConfig.Name)" -Level Success
        } else {
            Write-Log "Would migrate alert: $($AlertConfig.Name)" -Level Info
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to migrate alert '$($AlertConfig.Name)': $($_.Exception.Message)" -Level Error
        return $false
    }
    finally {
        # Clean up temporary file
        if ($tempFile -and (Test-Path $tempFile)) {
            try {
                Remove-Item $tempFile -Force
            }
            catch {
                Write-Log "Warning: Could not delete temporary file $tempFile" -Level Warning
            }
        }
    }
}

# Main execution function
function Start-AlertMigration {
    param(
        [string]$SourceHost,
        [string]$DestinationHost
    )
    
    $connections = $null
    $migratedCount = 0
    $skippedCount = 0
    $errorCount = 0
    
    try {
        # Initialize module
        Initialize-SwisPowerShell
        
        # Establish connections
        $connections = Connect-SolarWindsServers -SourceHost $SourceHost -DestinationHost $DestinationHost
        
        # Get alert configurations
        $sourceAlerts = Get-AlertConfigurations -SwisConnection $connections.Source -ServerType "Source"
        $destinationAlerts = Get-AlertConfigurations -SwisConnection $connections.Destination -ServerType "Destination"
        
        # Convert destination alerts to simple array for faster lookup
        $destinationAlertNames = $destinationAlerts | ForEach-Object { $_.Name }
        
        Write-Log "Starting migration process..."
        Write-Log "Source alerts (enabled): $($sourceAlerts.Count)"
        Write-Log "Destination alerts (total): $($destinationAlerts.Count)"
        
        # Process each source alert
        $alertCounter = 0
        foreach ($sourceAlert in $sourceAlerts) {
            $alertCounter++
            
            # Check if alert already exists on destination
            if (Test-AlertExists -DestinationConnection $connections.Destination -AlertName $sourceAlert.Name -DestinationAlerts $destinationAlertNames) {
                Write-Log "Alert already exists on destination, skipping: $($sourceAlert.Name)"
                $skippedCount++
            } else {
                # Migrate the alert
                $success = Export-AndMigrateAlert -SourceConnection $connections.Source -DestinationConnection $connections.Destination -AlertConfig $sourceAlert -AlertNumber $alertCounter
                
                if ($success) {
                    $migratedCount++
                } else {
                    $errorCount++
                }
            }
            
            # Progress indicator
            if ($alertCounter % 10 -eq 0) {
                Write-Progress -Activity "Migrating Alerts" -Status "Processed $alertCounter of $($sourceAlerts.Count)" -PercentComplete (($alertCounter / $sourceAlerts.Count) * 100)
            }
        }
        
        # Final summary
        Write-Log "=== Migration Summary ===" -Level Success
        Write-Log "Total source alerts: $($sourceAlerts.Count)" -Level Info
        Write-Log "Successfully migrated: $migratedCount" -Level Success
        Write-Log "Skipped (already exist): $skippedCount" -Level Info
        Write-Log "Errors: $errorCount" -Level $(if ($errorCount -gt 0) { "Warning" } else { "Info" })
        
        if ($WhatIfPreference) {
            Write-Log "This was a WhatIf run - no actual changes were made" -Level Info
        }
        
    }
    catch {
        Write-Log "Critical error during migration: $($_.Exception.Message)" -Level Error
        throw
    }
    finally {
        # Clean up connections
        if ($connections) {
            try {
                if ($connections.Source) { $connections.Source.Dispose() }
                if ($connections.Destination) { $connections.Destination.Dispose() }
                Write-Log "Connections closed successfully"
            }
            catch {
                Write-Log "Warning: Error closing connections: $($_.Exception.Message)" -Level Warning
            }
        }
        
        Write-Complete-Progress
    }
}

# Start the migration process
try {
    Write-Log "Starting SolarWinds Alert Migration Script" -Level Success
    Write-Log "Source: $SourceHostname" -Level Info
    Write-Log "Destination: $DestinationHostname" -Level Info
    Write-Log "Log file: $LogPath" -Level Info
    
    if ($WhatIfPreference) {
        Write-Log "Running in WhatIf mode - no changes will be made" -Level Warning
    }
    
    Start-AlertMigration -SourceHost $SourceHostname -DestinationHost $DestinationHost
    
    Write-Log "Migration completed successfully!" -Level Success
}
catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level Error
    exit 1
}
finally {
    Write-Log "Script execution finished" -Level Info
}