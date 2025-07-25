#Requires -Version 5.1
<#
.SYNOPSIS
    Updates SolarWinds hardware sensor thresholds for specified sensor types.

.DESCRIPTION
    This script connects to SolarWinds Orion and updates warning and critical thresholds
    for hardware sensors matching the specified filter criteria.

.PARAMETER OrionServer
    The hostname or IP address of the SolarWinds Orion server (default: localhost)

.PARAMETER Username
    Username for SolarWinds authentication

.PARAMETER Password
    Password for SolarWinds authentication (consider using SecureString)

.PARAMETER HardwareSensor
    The hardware sensor type to filter for (default: "Transceiver Receive Power")

.PARAMETER WhatIf
    Show what would be changed without actually making changes

.EXAMPLE
    .\Update-SolarWindsThresholds.ps1 -WhatIf
    Shows what thresholds would be updated without making changes

.EXAMPLE
    .\Update-SolarWindsThresholds.ps1 -OrionServer "solarwinds.company.com" -Username "admin"
    Updates thresholds on the specified server
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$OrionServer = "localhost",
    [Parameter(Mandatory = $false)]
    [string]$Username = "Loop1",
    [Parameter(Mandatory = $false)]
    [SecureString]$SecurePassword,
    [string]$HardwareSensor = "Transceiver Receive Power",
    [switch]$WhatIf
)

# Configuration
$WarningThresholdValue = -13.9
$CriticalThresholdValue = 2
$InvalidValue = -40

# Function to create threshold expressions
function New-ThresholdExpression {
    param(
        [double]$ThresholdValue,
        [string]$Operator,
        [double]$InvalidValue = -40
    )
    
    return @"
<Expr xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Reporting.Models.Selection" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
    <Child>
        <Expr>
            <Child>
                <Expr>
                    <Child i:nil="true"/>
                    <NodeType>Field</NodeType>
                    <Value>Value</Value>
                </Expr>
                <Expr>
                    <Child i:nil="true"/>
                    <NodeType>Constant</NodeType>
                    <Value>$InvalidValue</Value>
                </Expr>
            </Child>
            <NodeType>Operator</NodeType>
            <Value>!=</Value>
        </Expr>
        <Expr>
            <Child>
                <Expr>
                    <Child i:nil="true"/>
                    <NodeType>Field</NodeType>
                    <Value>Value</Value>
                </Expr>
                <Expr>
                    <Child i:nil="true"/>
                    <NodeType>Constant</NodeType>
                    <Value>$ThresholdValue</Value>
                </Expr>
            </Child>
            <NodeType>Operator</NodeType>
            <Value>$Operator</Value>
        </Expr>
    </Child>
    <NodeType>Operator</NodeType>
    <Value>AND</Value>
</Expr>
"@
}

# Function to safely connect to SolarWinds
function Connect-SolarWinds {
    param(
        [string]$Server,
        [string]$User,
        [SecureString]$SecurePass
    )
    
    try {
        Write-Host "Connecting to SolarWinds server: $Server" -ForegroundColor Green
        
        if ($SecurePass) {
            $credential = New-Object System.Management.Automation.PSCredential($User, $SecurePass)
            $swis = Connect-Swis -Hostname $Server -Credential $credential
        } else {
            # Fallback to prompting for password
            $swis = Connect-Swis -Hostname $Server -UserName $User
        }
        
        # Test connection
        $null = Get-SwisData -SwisConnection $swis -Query "SELECT TOP 1 NodeID FROM Orion.Nodes"
        Write-Host "Successfully connected to SolarWinds" -ForegroundColor Green
        return $swis
    }
    catch {
        Write-Error "Failed to connect to SolarWinds: $($_.Exception.Message)"
        throw
    }
}

# Function to get hardware sensors
function Get-HardwareSensors {
    param(
        [object]$SwisConnection,
        [string]$SensorFilter
    )
    
    $swqlQuery = @"
SELECT
    hh.NodeID,
    hh.ID,
    hh.HardwareInfoID,
    hh.HardwareCategoryStatusID,
    hh.node.caption,
    hh.Name,
    hh.OriginalStatus,
    hh.IsDeleted,
    hh.HardwareCategoryID,
    hh.IsDisabled,
    hh.StatusDescription,
    hh.STATUS,
    hh.Uri,
    hh.hardwareitemthreshold.warning,
    hh.hardwareitemthreshold.critical
FROM
    Orion.HardwareHealth.HardwareItem AS hh
WHERE
    hh.name LIKE '%$SensorFilter%'
    AND hh.IsDeleted = 0
    AND hh.IsDisabled = 0
ORDER BY
    hh.node.caption, hh.Name
"@
    
    try {
        Write-Host "Querying for hardware sensors matching: '$SensorFilter'" -ForegroundColor Yellow
        $sensors = Get-SwisData -SwisConnection $SwisConnection -Query $swqlQuery
        Write-Host "Found $($sensors.Count) matching sensors" -ForegroundColor Green
        return $sensors
    }
    catch {
        Write-Error "Failed to query hardware sensors: $($_.Exception.Message)"
        throw
    }
}

# Function to update sensor thresholds
function Update-SensorThresholds {
    param(
        [object]$SwisConnection,
        [object]$Sensor,
        [string]$WarningThreshold,
        [string]$CriticalThreshold,
        [switch]$WhatIf
    )
    
    $sensorInfo = "$($Sensor.Name) on $($Sensor.caption)"
    
    if ($WhatIf) {
        Write-Host "WHAT IF: Would update thresholds for $sensorInfo" -ForegroundColor Cyan
        return $true
    }
    
    try {
        Write-Host "Updating thresholds for $sensorInfo" -ForegroundColor Yellow
        
        Invoke-SwisVerb -SwisConnection $SwisConnection `
                       -EntityName 'Orion.HardwareHealth.HardwareItemThreshold' `
                       -Verb 'SetThreshold' `
                       -Arguments $Sensor.ID, $WarningThreshold, $CriticalThreshold
        
        Write-Host "Successfully updated thresholds for $sensorInfo" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to update thresholds for $sensorInfo : $($_.Exception.Message)"
        return $false
    }
}

# Main execution
try {
    # Handle password securely
    if (-not $SecurePassword -and $Username) {
        Write-Host "Enter password for user '$Username':" -ForegroundColor Yellow
        $SecurePassword = Read-Host -AsSecureString
    }
    
    # Connect to SolarWinds
    $swis = Connect-SolarWinds -Server $OrionServer -User $Username -SecurePass $SecurePassword
    
    # Create threshold expressions
    $warningThreshold = New-ThresholdExpression -ThresholdValue $WarningThresholdValue -Operator "&lt;=" -InvalidValue $InvalidValue
    $criticalThreshold = New-ThresholdExpression -ThresholdValue $CriticalThresholdValue -Operator "&gt;=" -InvalidValue $InvalidValue
    
    # Get hardware sensors
    $sensors = Get-HardwareSensors -SwisConnection $swis -SensorFilter $HardwareSensor
    
    if ($sensors.Count -eq 0) {
        Write-Warning "No sensors found matching filter: '$HardwareSensor'"
        return
    }
    
    # Display summary
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "- Server: $OrionServer" -ForegroundColor White
    Write-Host "- Sensor Filter: $HardwareSensor" -ForegroundColor White
    Write-Host "- Sensors Found: $($sensors.Count)" -ForegroundColor White
    Write-Host "- Warning Threshold: Value <= $WarningThresholdValue (and != $InvalidValue)" -ForegroundColor White
    Write-Host "- Critical Threshold: Value >= $CriticalThresholdValue (and != $InvalidValue)" -ForegroundColor White
    
    if ($WhatIf) {
        Write-Host "- Mode: WHAT IF (no changes will be made)" -ForegroundColor Cyan
    }
    
    # Confirm before proceeding
    if (-not $WhatIf) {
        $confirmation = Read-Host "`nDo you want to proceed with updating thresholds? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-Host "Operation cancelled by user" -ForegroundColor Yellow
            return
        }
    }
    
    # Update thresholds
    Write-Host "`nUpdating sensor thresholds..." -ForegroundColor Cyan
    $successCount = 0
    $errorCount = 0
    
    foreach ($sensor in $sensors) {
        $result = Update-SensorThresholds -SwisConnection $swis `
                                         -Sensor $sensor `
                                         -WarningThreshold $warningThreshold `
                                         -CriticalThreshold $criticalThreshold `
                                         -WhatIf:$WhatIf
        
        if ($result) {
            $successCount++
        } else {
            $errorCount++
        }
        
        # Add small delay to avoid overwhelming the server
        Start-Sleep -Milliseconds 100
    }
    
    # Final summary
    Write-Host "`nOperation completed:" -ForegroundColor Cyan
    Write-Host "- Successful updates: $successCount" -ForegroundColor Green
    Write-Host "- Failed updates: $errorCount" -ForegroundColor Red
    
    if ($WhatIf) {
        Write-Host "- No actual changes were made (WhatIf mode)" -ForegroundColor Cyan
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}
finally {
    # Cleanup connection if it exists
    if ($swis) {
        try {
            $swis.Dispose()
            Write-Host "SolarWinds connection closed" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to properly close SolarWinds connection"
        }
    }
}