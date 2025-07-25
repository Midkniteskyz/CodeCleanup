# Define the file containing server names
$ServerListPath = "C:\Path\To\servers.txt"

# Read the list of server names
$Servers = Get-Content -Path $ServerListPath

# Initialize an array to hold the results
$Results = @()

# Iterate through each server
foreach ($Server in $Servers) {
    try {
        # Use PowerShell remoting to gather information
        $SystemInfo = Invoke-Command -ComputerName $Server -ScriptBlock {
            $hostname = $env:COMPUTERNAME
            $ipAddresses = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -ne "127.0.0.1" }).IPAddress -join ", "
            $os = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
            $cpuCount = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors | Measure-Object -Sum | Select-Object -ExpandProperty Sum
            $ram = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB -as [int]
            $drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
                "$($_.DeviceID): $([math]::Round($_.Size / 1GB, 2)) GB"
            } -join "; "

            [PSCustomObject]@{
                Hostname = $hostname
                IP = $ipAddresses
                OS = $os
                CPUCount = $cpuCount
                RAM = "$ram GB"
                Drives = $drives
            }
        }

        # Add the information to the results array
        $Results += $SystemInfo
    } catch {
        Write-Warning "Failed to retrieve information from $Server : $_"
    }
}

# Output the results to a CSV file
$Results | Export-Csv -Path "C:\Path\To\ServerInfo.csv" -NoTypeInformation

# Display the results in the console
$Results
