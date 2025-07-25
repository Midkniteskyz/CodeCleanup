<#
.SYNOPSIS
    Script to query system information from local or remote machines.
.DESCRIPTION
    This script gathers detailed system information including OS, CPU, RAM, .NET Framework, 
    disk drives, and SQL Server versions from either a local machine, a remote machine, 
    a list of machines, or machines specified in a text file.
.PARAMETER ComputerName
    Specifies a single computer name to query.
.PARAMETER ComputerList
    Specifies an array of computer names to query.
.PARAMETER InputFile
    Specifies a text file containing computer names (one per line) to query.
.PARAMETER LocalMachine
    Switch to query the local machine.
.PARAMETER OutputFile
    Specifies a path to save the results to a CSV file.
.EXAMPLE
    .\Get-SystemInfo.ps1 -LocalMachine
.EXAMPLE
    .\Get-SystemInfo.ps1 -ComputerName "Server01"
.EXAMPLE
    .\Get-SystemInfo.ps1 -ComputerList "Server01","Server02","Server03"
.EXAMPLE
    .\Get-SystemInfo.ps1 -InputFile "C:\Servers.txt" -OutputFile "C:\Results.csv"
#>

[CmdletBinding(DefaultParameterSetName='Local')]
param(
    [Parameter(ParameterSetName='Single')]
    [string]$ComputerName,
    
    [Parameter(ParameterSetName='Multiple')]
    [string[]]$ComputerList,
    
    [Parameter(ParameterSetName='File')]
    [string]$InputFile,
    
    [Parameter(ParameterSetName='Local')]
    [switch]$LocalMachine,
    
    [Parameter()]
    [string]$OutputFile
)

function Get-SystemInformation {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Computer
    )
    
    Write-Host "Querying system information for $Computer..." -ForegroundColor Cyan
    
    try {
        # Test if the computer is online
        if (-not (Test-Connection -ComputerName $Computer -Count 1 -Quiet)) {
            Write-Warning "Cannot connect to $Computer. Computer is offline or unreachable."
            return [PSCustomObject]@{
                ComputerName = $Computer
                Status = "Offline"
                OS = "N/A"
                CPU = "N/A"
                CPUCores = "N/A"
                RAMTotal = "N/A"
                DotNetVersions = "N/A"
                Drives = "N/A"
                SQLServerInstalled = "N/A"
                SQLServerVersions = "N/A"
            }
        }
        
        # Use Invoke-Command to execute commands remotely
        $results = Invoke-Command -ComputerName $Computer -ScriptBlock {
            # Get OS information
            $os = Get-WmiObject -Class Win32_OperatingSystem
            $osInfo = "$($os.Caption) $($os.Version) Build $($os.BuildNumber) $($os.OSArchitecture)"
            
            # Get CPU information
            $cpu = Get-WmiObject -Class Win32_Processor
            $cpuInfo = if ($cpu -is [array]) { $cpu[0].Name } else { $cpu.Name }
            $cpuCores = if ($cpu -is [array]) { ($cpu | Measure-Object -Property NumberOfCores -Sum).Sum } else { $cpu.NumberOfCores }
            
            # Get RAM information
            $ram = Get-WmiObject -Class Win32_ComputerSystem
            $ramTotalGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
            
            # Get .NET Framework versions
            $dotNetKeys = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP" -Recurse | 
                          Where-Object { $_.GetValue("Version") -ne $null } | 
                          ForEach-Object { $_.GetValue("Version") }
            
            # Add .NET 4.5+ version check (stored differently in registry)
            $net4Registry = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue
            if ($net4Registry) {
                $release = $net4Registry.Release
                $net4Version = switch ($release) {
                    { $_ -ge 528040 } { "4.8" }
                    { $_ -ge 461808 } { "4.7.2" }
                    { $_ -ge 461308 } { "4.7.1" }
                    { $_ -ge 460798 } { "4.7" }
                    { $_ -ge 394802 } { "4.6.2" }
                    { $_ -ge 394254 } { "4.6.1" }
                    { $_ -ge 393295 } { "4.6" }
                    { $_ -ge 379893 } { "4.5.2" }
                    { $_ -ge 378675 } { "4.5.1" }
                    { $_ -ge 378389 } { "4.5" }
                    default { $null }
                }
                if ($net4Version) {
                    $dotNetKeys += $net4Version
                }
            }
            
            $dotNetVersions = $dotNetKeys | Sort-Object -Unique
            
            # Get drive information
            $driveInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | 
                         ForEach-Object {
                             $driveSizeGB = [math]::Round($_.Size / 1GB, 2)
                             $driveFreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                             "$($_.DeviceID) (Label: $($_.VolumeName), Size: $driveSizeGB GB, Free: $driveFreeGB GB)"
                         }
            
            # Check if SQL Server is installed and get version info
            $sqlInstances = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" -ErrorAction SilentlyContinue
            $sqlVersions = @()
            
            if ($sqlInstances) {
                foreach ($instance in $sqlInstances.PSObject.Properties) {
                    $instanceName = $instance.Name
                    $instancePath = $instance.Value
                    
                    $setupRegistry = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instancePath\Setup" -ErrorAction SilentlyContinue
                    if ($setupRegistry) {
                        $version = $setupRegistry.Version
                        $edition = $setupRegistry.Edition
                        $sqlVersions += "$instanceName - Version: $version, Edition: $edition"
                    }
                }
            }
            
            return [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                Status = "Online"
                OS = $osInfo
                CPU = $cpuInfo
                CPUCores = $cpuCores
                RAMTotal = "$ramTotalGB GB"
                DotNetVersions = ($dotNetVersions -join ", ")
                Drives = ($driveInfo -join "; ")
                SQLServerInstalled = ($sqlVersions.Count -gt 0)
                SQLServerVersions = if ($sqlVersions.Count -gt 0) { ($sqlVersions -join "; ") } else { "Not Installed" }
            }
        } -ErrorAction Stop
        
        return $results
    }
    catch {
        Write-Warning "Error querying $Computer. Error: $_"
        return [PSCustomObject]@{
            ComputerName = $Computer
            Status = "Error"
            OS = "Error: $_"
            CPU = "N/A"
            CPUCores = "N/A"
            RAMTotal = "N/A"
            DotNetVersions = "N/A"
            Drives = "N/A"
            SQLServerInstalled = "N/A"
            SQLServerVersions = "N/A"
        }
    }
}

# Determine which computers to query
$computers = @()

switch ($PSCmdlet.ParameterSetName) {
    'Local' {
        $computers += $env:COMPUTERNAME
    }
    'Single' {
        $computers += $ComputerName
    }
    'Multiple' {
        $computers += $ComputerList
    }
    'File' {
        if (Test-Path $InputFile) {
            $computers += Get-Content $InputFile
        }
        else {
            Write-Error "Input file not found: $InputFile"
            exit
        }
    }
}

# Query each computer and collect results
$results = @()
foreach ($computer in $computers) {
    $systemInfo = Get-SystemInformation -Computer $computer
    $results += $systemInfo
    
    # Display results for each computer
    Write-Host "`n===== System Information for $computer =====" -ForegroundColor Green
    Write-Host "Status: $($systemInfo.Status)"
    if ($systemInfo.Status -eq "Online") {
        Write-Host "OS: $($systemInfo.OS)"
        Write-Host "CPU: $($systemInfo.CPU)"
        Write-Host "CPU Cores: $($systemInfo.CPUCores)"
        Write-Host "RAM: $($systemInfo.RAMTotal)"
        Write-Host "DotNet Versions: $($systemInfo.DotNetVersions)"
        Write-Host "Drives:"
        $systemInfo.Drives -split ";" | ForEach-Object { Write-Host "  - $_" }
        Write-Host "SQL Server Installed: $($systemInfo.SQLServerInstalled)"
        if ($systemInfo.SQLServerInstalled -eq $true) {
            Write-Host "SQL Server Versions:"
            $systemInfo.SQLServerVersions -split ";" | ForEach-Object { Write-Host "  - $_" }
        }
    }
}

# Save results to CSV file if specified
if ($OutputFile) {
    $results | Export-Csv -Path $OutputFile -NoTypeInformation
    Write-Host "`nResults saved to: $OutputFile" -ForegroundColor Yellow
}

Write-Host "`nQuery completed for $($results.Count) computer(s)." -ForegroundColor Green