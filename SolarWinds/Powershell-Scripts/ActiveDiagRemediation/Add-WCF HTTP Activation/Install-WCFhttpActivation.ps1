<#
.SYNOPSIS
    Installs the .NET Framework WCF HTTP Activation feature on a Windows Server.
.DESCRIPTION
    This script uses PowerShell to enable the .NET Framework WCF HTTP Activation feature using the `Install-WindowsFeature` cmdlet.
    Administrative privileges are required to execute this script.
#>

# Check if the script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an Administrator."
    exit
}

try {
    Write-Host "Installing .NET Framework WCF HTTP Activation feature..." -ForegroundColor Green

    # Install the WCF HTTP Activation feature
    $featureName = "NET-WCF-HTTP-Activation45"
    Install-WindowsFeature -Name $featureName -IncludeManagementTools -Verbose

    # Verify if the feature is installed successfully
    $feature = Get-WindowsFeature -Name $featureName
    if ($feature.Installed) {
        Write-Host "The .NET Framework WCF HTTP Activation feature has been installed successfully." -ForegroundColor Cyan
    } else {
        Write-Error "The installation of the .NET Framework WCF HTTP Activation feature failed."
    }
}
catch {
    Write-Error "An error occurred while installing the .NET Framework WCF HTTP Activation feature. Error: $_"
}
