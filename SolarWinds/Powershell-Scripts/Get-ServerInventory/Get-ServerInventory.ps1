<#
.SYNOPSIS
    Comprehensive Windows Server Inventory Script
.DESCRIPTION
    Collects detailed system information including hostname, IP, OS, CPU, RAM, and drive details
.PARAMETER ComputerName
    List of server names to inventory
.PARAMETER Credential
    Optional credential for remote server connections
.EXAMPLE
    .\Get-ServerInventory.ps1 -ComputerName (Get-Content servers.txt)
    Retrieves inventory from servers listed in a text file
.EXAMPLE
    .\Get-ServerInventory.ps1 -ComputerName "Server1", "Server2" -Credential (Get-Credential)
    Retrieves inventory using specific credentials
#>
param (
    [Parameter(ValueFromPipeline=$true)]
    [string[]]$ComputerName = $env:COMPUTERNAME,
    
    [System.Management.Automation.PSCredential]$Credential
)

# Function to get comprehensive server details
function Get-ServerInventoryDetails {
    param (
        [string]$Computer,
        [System.Management.Automation.PSCredential]$RemoteCredential
    )

    # Prepare remote session parameters
    $sessionParams = @{
        ComputerName = $Computer
    }
    if ($RemoteCredential) {
        $sessionParams.Credential = $RemoteCredential
    }

    try {
        # Collect server inventory details
        $serverDetails = Invoke-Command @sessionParams -ScriptBlock {
            # Collect system information
            $os = Get-CimInstance Win32_OperatingSystem
            $comp = Get-CimInstance Win32_ComputerSystem
            $cpu = Get-CimInstance Win32_Processor
            
            # Get IP Addresses
            $ipAddresses = (Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4' -and $_.PrefixOrigin -ne 'WellKnown'}).IPAddress -join ', '

            # Get Drive Information
            $drives = Get-Volume | Where-Object { $_.DriveLetter } | ForEach-Object {
                [PSCustomObject]@{
                    DriveLetter = $_.DriveLetter
                    Label = $_.FileSystemLabel
                    SizeGB = [math]::Round($_.Size / 1GB, 2)
                    FreeSpaceGB = [math]::Round($_.SizeRemaining / 1GB, 2)
                }
            }

            # Construct return object
            [PSCustomObject]@{
                Hostname = $env:COMPUTERNAME
                IPAddresses = $ipAddresses
                OperatingSystem = $os.Caption
                OSVersion = $os.Version
                CPUCount = $comp.NumberOfProcessors
                CPUCores = $cpu.NumberOfCores
                RAMTotalGB = [math]::Round($comp.TotalPhysicalMemory / 1GB, 2)
                Drives = $drives
            }
        }

        return $serverDetails
    }
    catch {
        Write-Error "Failed to retrieve inventory information from $Computer. Error: $_"
        return $null
    }
}

# Main script execution
$inventoryResults = @()
foreach ($computer in $ComputerName) {
    Write-Host "Querying $computer..." -ForegroundColor Cyan
    $computerInventory = Get-ServerInventoryDetails -Computer $computer -RemoteCredential $Credential
    if ($computerInventory) {
        $inventoryResults += $computerInventory
    }
}

# Output and export results
if ($inventoryResults) {
    # Display detailed results
    foreach ($result in $inventoryResults) {
        Write-Host "`nServer Inventory Details for $($result.Hostname)" -ForegroundColor Green
        Write-Host "-------------------------------------------"
        
        # Main server details
        $result | Select-Object Hostname, IPAddresses, OperatingSystem, OSVersion, 
                                CPUCount, CPUCores, RAMTotalGB | Format-List

        # Drive details
        Write-Host "`nDrive Information:" -ForegroundColor Yellow
        $result.Drives | Format-Table -AutoSize
        
        Write-Host "`n" -NoNewline
    }

    # Export to CSV
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputPath = "C:\Temp\ServerInventory_$timestamp.csv"
    
    # Flatten drive information for CSV export
    $exportData = $inventoryResults | ForEach-Object {
        $baseInfo = $_ | Select-Object Hostname, IPAddresses, OperatingSystem, OSVersion, 
                                        CPUCount, CPUCores, RAMTotalGB
        
        # If no drives, create a record with empty drive info
        if ($_.Drives.Count -eq 0) {
            $baseInfo | Add-Member -NotePropertyName DriveLetter -NotePropertyValue $null -PassThru |
            Add-Member -NotePropertyName DriveLabel -NotePropertyValue $null -PassThru |
            Add-Member -NotePropertyName DriveSizeGB -NotePropertyValue $null -PassThru |
            Add-Member -NotePropertyName DriveFreeSpaceGB -NotePropertyValue $null -PassThru
        }
        else {
            # Create a record for each drive
            $_.Drives | ForEach-Object {
                $driveRecord = $baseInfo | Select-Object -Property *
                $driveRecord | Add-Member -NotePropertyName DriveLetter -NotePropertyValue $_.DriveLetter -PassThru |
                Add-Member -NotePropertyName DriveLabel -NotePropertyValue $_.Label -PassThru |
                Add-Member -NotePropertyName DriveSizeGB -NotePropertyValue $_.SizeGB -PassThru |
                Add-Member -NotePropertyName DriveFreeSpaceGB -NotePropertyValue $_.FreeSpaceGB
            }
        }
    }

    # Export to CSV
    $exportData | Export-Csv -Path $outputPath -NoTypeInformation
    Write-Host "Detailed inventory exported to $outputPath" -ForegroundColor Magenta
}
else {
    Write-Error "No server inventory information could be retrieved."
}