<#
.SYNOPSIS
    Disables TLS 1.1 for both the server and client by modifying registry keys.
.DESCRIPTION
    This script ensures that the registry keys and values required to disable TLS 1.0 & TLS 1.1 are created if they do not exist and sets the `Enabled` DWORD value to 0. 
    Then, the system is restarted to apply the changes.
    See KB: SF19333 for details.
#>

# Define the registry paths and settings
$regPaths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server",
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client",
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server",
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"
)

# Iterate over each path to ensure the keys and values are configured
foreach ($regPath in $regPaths) {
    try {
        # Check if the registry key exists; create it if not
        if (-not (Test-Path -Path $regPath)) {
            Write-Host "Creating registry key: $regPath" -ForegroundColor Yellow
            New-Item -Path $regPath -Force | Out-Null
        }

        # Set the 'Enabled' DWORD value to 0
        Write-Host "Setting 'Enabled' value to 0 in $regPath" -ForegroundColor Green
        New-ItemProperty -Path $regPath -Name "Enabled" -Value 0 -PropertyType DWord -Force | Out-Null
    }
    catch {
        Write-Error "Failed to update registry at $regPath. Error: $_"
    }
}


# Prompt to restart the computer
# Write-Host "The system will now restart to apply the changes." -ForegroundColor Cyan
# Start-Sleep -Seconds 5
# Restart-Computer -Force
