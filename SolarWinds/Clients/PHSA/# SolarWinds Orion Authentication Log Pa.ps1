# SolarWinds Orion Authentication Log Parser
# This script parses SolarWinds Orion log files to extract authentication information

param(
    [Parameter(Mandatory=$true)]
    [string]$LogFilePath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = $null,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowSuccessOnly = $false
)

# Check if log file exists
if (-not (Test-Path $LogFilePath)) {
    Write-Error "Log file not found: $LogFilePath"
    exit 1
}

# Initialize results array
$authResults = @()

# Read the log file
$logContent = Get-Content $LogFilePath

# Process each line
foreach ($line in $logContent) {
    # Skip empty lines
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }
    
    # Extract timestamp (first part of the log line)
    if ($line -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3})') {
        $timestamp = $matches[1]
    } else {
        continue
    }
    
    # Look for authentication events
    $authEvent = $null
    
    # Pattern 1: Successful authentication
    if ($line -match 'Successfully retrieved WindowsIdentity for user (.+?)\.') {
        $user = $matches[1]
        $authEvent = [PSCustomObject]@{
            Timestamp = $timestamp
            User = $user
            Event = "Authentication Attempt"
            Status = "SUCCESS"
            Group = ""
            Details = "Successfully retrieved WindowsIdentity"
        }
    }
    
    # Pattern 2: Group resolution (indicates successful authentication)
    elseif ($line -match 'Resolved group: (.+?) for identity: (.+?)\.') {
        $group = $matches[1]
        $user = $matches[2]
        $authEvent = [PSCustomObject]@{
            Timestamp = $timestamp
            User = $user
            Event = "Group Resolution"
            Status = "SUCCESS"
            Group = $group
            Details = "User assigned to group"
        }
    }
    
    # Pattern 3: Failed authentication attempts (add more patterns as needed)
    elseif ($line -match 'Authentication failed|Login failed|Access denied' -and $line -match 'user (.+?)[\s\.]') {
        $user = $matches[1]
        $authEvent = [PSCustomObject]@{
            Timestamp = $timestamp
            User = $user
            Event = "Authentication Attempt"
            Status = "FAILED"
            Group = ""
            Details = "Authentication failed"
        }
    }
    
    # Add the event to results if found
    if ($authEvent) {
        $authResults += $authEvent
    }
}

# Filter results if ShowSuccessOnly is specified
if ($ShowSuccessOnly) {
    $authResults = $authResults | Where-Object { $_.Status -eq "SUCCESS" }
}

# Sort results by timestamp
$authResults = $authResults | Sort-Object Timestamp

# Display results
Write-Host "`n=== SolarWinds Authentication Log Analysis ===" -ForegroundColor Cyan
Write-Host "Log File: $LogFilePath" -ForegroundColor Yellow
Write-Host "Total Events Found: $($authResults.Count)" -ForegroundColor Yellow
Write-Host "Analysis Date: $(Get-Date)" -ForegroundColor Yellow
Write-Host "`n" + "="*80 + "`n" -ForegroundColor Cyan

if ($authResults.Count -eq 0) {
    Write-Host "No authentication events found in the log file." -ForegroundColor Red
    exit 0
}

# Display detailed results
foreach ($event in $authResults) {
    Write-Host "Timestamp: $($event.Timestamp)" -ForegroundColor White
    Write-Host "User: $($event.User)" -ForegroundColor Green
    Write-Host "Event: $($event.Event)" -ForegroundColor Magenta
    
    if ($event.Status -eq "SUCCESS") {
        Write-Host "Status: $($event.Status)" -ForegroundColor Green
    } else {
        Write-Host "Status: $($event.Status)" -ForegroundColor Red
    }
    
    if ($event.Group) {
        Write-Host "Group: $($event.Group)" -ForegroundColor Cyan
    }
    
    Write-Host "Details: $($event.Details)" -ForegroundColor Gray
    Write-Host "-" * 50
}

# Summary statistics
$successCount = ($authResults | Where-Object { $_.Status -eq "SUCCESS" }).Count
$failCount = ($authResults | Where-Object { $_.Status -eq "FAILED" }).Count
$uniqueUsers = ($authResults | Select-Object -ExpandProperty User | Sort-Object -Unique).Count

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Successful Events: $successCount" -ForegroundColor Green
Write-Host "Failed Events: $failCount" -ForegroundColor Red
Write-Host "Unique Users: $uniqueUsers" -ForegroundColor Yellow

# Display unique users
$users = $authResults | Select-Object -ExpandProperty User | Sort-Object -Unique
Write-Host "`nUnique Users Found:" -ForegroundColor Cyan
foreach ($user in $users) {
    Write-Host "  - $user" -ForegroundColor White
}

# Display unique groups
$groups = $authResults | Where-Object { $_.Group } | Select-Object -ExpandProperty Group | Sort-Object -Unique
if ($groups.Count -gt 0) {
    Write-Host "`nGroups Found:" -ForegroundColor Cyan
    foreach ($group in $groups) {
        Write-Host "  - $group" -ForegroundColor White
    }
}

# Export to CSV if output path is specified
if ($OutputPath) {
    try {
        $authResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "`nResults exported to: $OutputPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to export results: $($_.Exception.Message)"
    }
}

# Example usage information
Write-Host "`n=== Usage Examples ===" -ForegroundColor Cyan
Write-Host "Basic usage:" -ForegroundColor Yellow
Write-Host "  .\script.ps1 -LogFilePath 'C:\path\to\logfile.log'" -ForegroundColor White
Write-Host "`nWith CSV export:" -ForegroundColor Yellow
Write-Host "  .\script.ps1 -LogFilePath 'C:\path\to\logfile.log' -OutputPath 'C:\path\to\results.csv'" -ForegroundColor White
Write-Host "`nShow only successful authentications:" -ForegroundColor Yellow
Write-Host "  .\script.ps1 -LogFilePath 'C:\path\to\logfile.log' -ShowSuccessOnly" -ForegroundColor White