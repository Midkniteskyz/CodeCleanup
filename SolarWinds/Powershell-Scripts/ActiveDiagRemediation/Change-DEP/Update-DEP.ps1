<#
.SYNOPSIS
    Configures DEP to "Turn on DEP for essential Windows programs and services only."
.DESCRIPTION
    This script modifies the DEP settings in the system to enable DEP for essential Windows programs and services only.
    Administrative privileges are required to run this script.
#>

# Check if the script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an Administrator."
    exit
}

try {
    # Registry path for DEP configuration
    $depRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"

    # DEP value for "Turn on DEP for essential Windows programs and services only"
    $depValue = "1"

    # Set the DEP configuration in the registry
    Write-Host "Configuring DEP to 'Turn on DEP for essential Windows programs and services only'..." -ForegroundColor Green
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ExecutionPolicy" -Value $depValue

    Write-Host "DEP has been configured successfully." -ForegroundColor Cyan

    # Prompt to restart the computer
    Write-Host "You must restart your computer for the changes to take effect." -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to configure DEP. Error: $_"
}