<#
.SYNOPSIS
    Retrieves detailed disk and volume information from local or remote servers.
.DESCRIPTION
    This script collects comprehensive information about disks, volumes, and storage,
    including physical disk details, logical volumes, free space, and file system information.
.PARAMETER ComputerName
    List of server names to query. If not specified, queries the local computer.
.PARAMETER Credential
    Optional credential for remote server connections.
.EXAMPLE
    .\Get-ServerStorageInfo.ps1 -ComputerName "Server1", "Server2"
    Retrieves storage information from multiple servers.
.EXAMPLE 
    .\Get-ServerStorageInfo.ps1 -ComputerName "RemoteServer" -Credential (Get-Credential)
    Retrieves storage information using specific credentials.
#>
param (
    [Parameter(ValueFromPipeline=$true)]
    [string[]]$ComputerName = $env:COMPUTERNAME,
    
    [System.Management.Automation.PSCredential]$Credential
)

# Function to get comprehensive disk and volume information
function Get-ServerStorageDetails {
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
        # Physical Disk Information
        $physicalDisks = Invoke-Command @sessionParams -ScriptBlock {
            Get-PhysicalDisk | Select-Object -Property DeviceId, 
                FriendlyName, 
                MediaType, 
                @{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB, 2)}}, 
                HealthStatus, 
                OperationalStatus
        }

        # Logical Volume Information
        $volumes = Invoke-Command @sessionParams -ScriptBlock {
            Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -Property `
                DriveLetter, 
                FileSystemLabel, 
                FileSystem, 
                @{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB, 2)}}, 
                @{Name='FreeSpaceGB';Expression={[math]::Round($_.SizeRemaining / 1GB, 2)}},
                @{Name='PercentFree';Expression={[math]::Round(($_.SizeRemaining / $_.Size) * 100, 2)}}
        }

        # Disk Partition Information
        $diskPartitions = Invoke-Command @sessionParams -ScriptBlock {
            Get-Partition | Select-Object -Property `
                DiskNumber, 
                PartitionNumber, 
                DriveLetter, 
                @{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB, 2)}}
        }

        # Combine and return results
        [PSCustomObject]@{
            ComputerName = $Computer
            PhysicalDisks = $physicalDisks
            Volumes = $volumes
            DiskPartitions = $diskPartitions
        }
    }
    catch {
        Write-Error "Failed to retrieve storage information from $Computer. Error: $_"
        return $null
    }
}

# Main script execution
$results = @()
foreach ($computer in $ComputerName) {
    $computerResults = Get-ServerStorageDetails -Computer $computer -RemoteCredential $Credential
    if ($computerResults) {
        $results += $computerResults
    }
}

# Output results
if ($results) {
    # Output to console
    foreach ($result in $results) {
        Write-Host "Storage Information for $($result.ComputerName)" -ForegroundColor Cyan
        
        Write-Host "`nPhysical Disks:" -ForegroundColor Green
        $result.PhysicalDisks | Format-Table -AutoSize
        
        Write-Host "`nVolumes:" -ForegroundColor Green
        $result.Volumes | Format-Table -AutoSize
        
        Write-Host "`nDisk Partitions:" -ForegroundColor Green
        $result.DiskPartitions | Format-Table -AutoSize
        
        Write-Host "`n---------------------------------`n" -ForegroundColor Yellow
    }

    # Optionally, export to CSV if needed
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputPath = "C:\Temp\ServerStorageReport_$timestamp.csv"
    $results | Export-Csv -Path $outputPath -NoTypeInformation
    Write-Host "Detailed report exported to $outputPath" -ForegroundColor Magenta
}
else {
    Write-Error "No storage information could be retrieved."
}