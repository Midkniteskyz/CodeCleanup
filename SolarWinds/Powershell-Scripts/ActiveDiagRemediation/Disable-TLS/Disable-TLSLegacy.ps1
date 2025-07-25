<#
.SYNOPSIS
    Disables TLS 1.0 and TLS 1.1 for both server and client by modifying registry keys.
.DESCRIPTION
    This script ensures that the registry keys and values required to disable TLS 1.0 & TLS 1.1 
    are created if they do not exist and sets the `Enabled` DWORD value to 0.
    The script supports:
    - Targeting a remote server
    - Automatic privilege elevation if needed
    - Configurable reboot options after changes are applied
    See KB: SF19333 for details.
.PARAMETER ComputerName
    The name of the remote computer to target. If not specified, runs on the local machine.
.PARAMETER Force
    If specified, doesn't prompt for confirmation before making changes.
.EXAMPLE
    .\Disable-TLSLegacy.ps1
    Runs the script on the local machine with prompts.
.EXAMPLE
    .\Disable-TLSLegacy.ps1 -ComputerName "RemoteServer01"
    Targets the remote server "RemoteServer01".
.NOTES
    Requires administrative privileges to modify registry keys.
    A system restart is required for changes to take effect.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ComputerName = $env:COMPUTERNAME,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

#region Functions
function Test-IsAdmin {
    # Check if the current PowerShell session is running with administrative privileges
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-ElevatedScript {
    # Re-launch the script with elevated permissions
    $scriptPath = $MyInvocation.PSCommandPath
    $argumentString = ""
    
    # Rebuild the argument string to pass to the elevated process
    if ($ComputerName -ne $env:COMPUTERNAME) {
        $argumentString += " -ComputerName '$ComputerName'"
    }
    if ($Force) {
        $argumentString += " -Force"
    }
    
    Write-Host "Elevating privileges to run the script..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $argumentString" -Verb RunAs
    exit
}
#endregion Functions

#region Main Script Execution
# Intro message
Write-Host "TLS 1.0 and TLS 1.1 Disablement Script" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Check for administrative privileges if targeting local machine
if ($ComputerName -eq $env:COMPUTERNAME -and -not (Test-IsAdmin)) {
    Write-Host "This script requires administrative privileges to modify registry keys." -ForegroundColor Yellow
    $elevate = Read-Host "Do you want to elevate privileges and continue? (Y/N)"
    if ($elevate -eq "Y" -or $elevate -eq "y") {
        Invoke-ElevatedScript
    } else {
        Write-Host "Operation cancelled. Administrative privileges are required." -ForegroundColor Red
        exit
    }
}

# Set up remote or local registry access
if ($ComputerName -ne $env:COMPUTERNAME) {
    Write-Host "Targeting remote server: $ComputerName" -ForegroundColor Cyan
    
    # Check if credentials are needed for remote access
    $credential = $null
    $testConnection = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
    
    if (-not $testConnection) {
        Write-Host "Cannot reach $ComputerName. Please verify the server name and network connectivity." -ForegroundColor Red
        exit
    }
    
    # Try to access registry to see if credentials are needed
    try {
        $testReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
        $testReg.Close()
    } catch {
        Write-Host "Access to remote registry requires credentials." -ForegroundColor Yellow
        $credential = Get-Credential -Message "Enter credentials for $ComputerName"
        
        if ($null -eq $credential) {
            Write-Host "No credentials provided. Operation cancelled." -ForegroundColor Red
            exit
        }
    }
}

# Confirm before proceeding
if (-not $Force) {
    Write-Host "This script will disable TLS 1.0 and TLS 1.1 on $ComputerName by modifying registry keys." -ForegroundColor Yellow
    $confirm = Read-Host "Do you want to continue? (Y/N)"
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-Host "Operation cancelled by user." -ForegroundColor Red
        exit
    }
}

# Define the registry paths and settings
$regPaths = @(
    "SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server",
    "SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client",
    "SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server",
    "SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"
)

# Track if any changes were made
$changesApplied = $false

# Define ScriptBlock to execute either locally or remotely
$scriptBlock = {
    param($regPaths)
    
    $results = @()
    
    foreach ($regPath in $regPaths) {
        $fullPath = "HKLM:\$regPath"
        $changed = $false
        
        try {
            # Check if the registry key exists; create it if not
            if (-not (Test-Path -Path $fullPath)) {
                New-Item -Path $fullPath -Force | Out-Null
                $changed = $true
            }

            # Check if the Enabled value exists and is set correctly
            $currentValue = Get-ItemProperty -Path $fullPath -Name "Enabled" -ErrorAction SilentlyContinue
            
            if ($null -eq $currentValue -or $currentValue.Enabled -ne 0) {
                New-ItemProperty -Path $fullPath -Name "Enabled" -Value 0 -PropertyType DWord -Force | Out-Null
                $changed = $true
            }
            
            $results += [PSCustomObject]@{
                Path = $regPath
                Success = $true
                Changed = $changed
                Error = $null
            }
        }
        catch {
            $results += [PSCustomObject]@{
                Path = $regPath
                Success = $false
                Changed = $false
                Error = $_.Exception.Message
            }
        }
    }
    
    return $results
}

# Execute registry modifications
Write-Host "Modifying registry settings..." -ForegroundColor Cyan

if ($ComputerName -eq $env:COMPUTERNAME) {
    $results = & $scriptBlock $regPaths
} else {
    # Decide whether to use credentials or not
    if ($null -ne $credential) {
        $results = Invoke-Command -ComputerName $ComputerName -Credential $credential -ScriptBlock $scriptBlock -ArgumentList (,$regPaths)
    } else {
        $results = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ArgumentList (,$regPaths)
    }
}

# Process and display results
foreach ($result in $results) {
    if ($result.Success) {
        $statusColor = "Green"
        $status = "Success"
        if ($result.Changed) {
            $changesApplied = $true
        }
    } else {
        $statusColor = "Red"
        $status = "Failed"
    }
    
    Write-Host "[$status] " -ForegroundColor $statusColor -NoNewline
    Write-Host "$($result.Path)" -ForegroundColor White
    
    if (-not $result.Success) {
        Write-Host "  Error: $($result.Error)" -ForegroundColor Red
    }
}

# Summary and reboot options
Write-Host "`nRegistry modification complete." -ForegroundColor Cyan

if ($changesApplied) {
    Write-Host "NOTE: Changes to TLS settings require a system restart to take effect." -ForegroundColor Yellow
    
    $rebootChoice = Read-Host "Do you want to restart the computer now? (Y/N)"
    if ($rebootChoice -eq "Y" -or $rebootChoice -eq "y") {
        $confirmReboot = Read-Host "Are you sure you want to restart $ComputerName now? (Y/N)"
        if ($confirmReboot -eq "Y" -or $confirmReboot -eq "y") {
            Write-Host "Initiating system restart..." -ForegroundColor Red
            
            if ($ComputerName -eq $env:COMPUTERNAME) {
                Restart-Computer -Force
            } else {
                if ($null -ne $credential) {
                    Restart-Computer -ComputerName $ComputerName -Credential $credential -Force
                } else {
                    Restart-Computer -ComputerName $ComputerName -Force
                }
            }
        } else {
            Write-Host "Restart cancelled. Please restart the system manually to apply the changes." -ForegroundColor Yellow
        }
    } else {
        Write-Host "No restart initiated. Please restart the system manually to apply the changes." -ForegroundColor Yellow
    }
} else {
    Write-Host "No changes were needed. TLS 1.0 and TLS 1.1 are already disabled." -ForegroundColor Green
}
#endregion Main Script Execution