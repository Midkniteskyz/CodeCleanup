param (
    [string[]]$ComputerName = 'localhost',
    [string]$ComputerListFile = ''
)

function Get-SystemInfo {
    param ([string]$Computer)

    Write-Host "--- Gathering Info for $Computer ---"

    try {
        $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer -ErrorAction Stop
        $cpu = Get-WmiObject -Class Win32_Processor -ComputerName $Computer -ErrorAction Stop
        $ram = Get-WmiObject -Class Win32_PhysicalMemory -ComputerName $Computer -ErrorAction Stop
        $drives = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $Computer -Filter "DriveType=3" -ErrorAction Stop
        $dotNet = Get-ChildItem -Path "\\$Computer\HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP" -Recurse | 
            Get-ItemProperty -Name Version -ErrorAction SilentlyContinue | 
            Where-Object { $_.Version -match "^\d+\.\d+" } | 
            Select-Object PSChildName, Version

        # Check for SQL Server
        $sqlRegPaths = @( 
            "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\Instance Names\SQL"
        )

        $sqlVersions = @()

        foreach ($regPath in $sqlRegPaths) {
            try {
                $instances = Get-Item -Path "\\$Computer\$regPath" -ErrorAction Stop
                foreach ($instance in $instances.GetValueNames()) {
                    $instanceId = $instances.GetValue($instance)
                    $verPath = "\\$Computer\HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\Setup"
                    $ver = Get-ItemProperty -Path $verPath -ErrorAction Stop
                    $sqlVersions += [PSCustomObject]@{
                        Instance = $instance
                        Version  = $ver.Version
                        Edition  = $ver.Edition
                    }
                }
            } catch {
                # SQL not found in this path
            }
        }

        return [PSCustomObject]@{
            Computer     = $Computer
            OS           = $os.Caption
            OSVersion    = $os.Version
            CPU          = $cpu.Name
            RAMGB        = [math]::Round(($ram.Capacity | Measure-Object -Sum).Sum / 1GB, 2)
            DotNet       = $dotNet
            Drives       = $drives | Select-Object DeviceID, @{n="Size(GB)";e={[math]::Round($_.Size / 1GB, 2)}}
            SQLVersions  = if ($sqlVersions.Count -gt 0) { $sqlVersions } else { "Not Installed" }
        }
    } catch {
        Write-Warning "Failed to get info from $Computer : $_"
        return $null
    }
}

# Build final computer list
$targets = @()

if ($ComputerListFile -and (Test-Path $ComputerListFile)) {
    $targets += Get-Content $ComputerListFile | Where-Object { $_ -and $_.Trim() -ne '' }
}

$targets += $ComputerName | Where-Object { $_ -and $_.Trim() -ne '' }
$targets = $targets | Sort-Object -Unique

$results = foreach ($target in $targets) {
    Get-SystemInfo -Computer $target
}

$results | Format-List
