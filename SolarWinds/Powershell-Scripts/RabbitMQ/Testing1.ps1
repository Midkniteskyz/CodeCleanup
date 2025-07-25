# RabbitMQ Troubleshooting Script
# Based on SolarWinds RabbitMQ troubleshooting guide
# https://support.solarwinds.com/SuccessCenter/s/article/Rabbit-MQ

param(
    [Parameter(Mandatory=$false)]
    [string]$RabbitMQInstallPath = "C:\Program Files\RabbitMQ Server\rabbitmq_server-3.8.0",
    
    [Parameter(Mandatory=$false)]
    [string]$ErlangInstallPath = "C:\Program Files\erl-24.0",
    
    [Parameter(Mandatory=$false)]
    [string]$LogOutputPath = "$env:USERPROFILE\Desktop\RabbitMQ_Diagnostics"
)

# Create output directory if it doesn't exist
if (!(Test-Path -Path $LogOutputPath)) {
    New-Item -ItemType Directory -Path $LogOutputPath | Out-Null
    Write-Host "Created output directory: $LogOutputPath" -ForegroundColor Green
}

$DiagnosticsFile = Join-Path -Path $LogOutputPath -ChildPath "RabbitMQ_Diagnostics_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$ErrorsFile = Join-Path -Path $LogOutputPath -ChildPath "RabbitMQ_Errors_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Function to write output to console and file
function Write-Diagnostic {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timestamp] [$Type] $Message"
    
    switch ($Type) {
        "INFO" { Write-Host $formattedMessage -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $formattedMessage -ForegroundColor Green }
        "WARNING" { Write-Host $formattedMessage -ForegroundColor Yellow }
        "ERROR" { 
            Write-Host $formattedMessage -ForegroundColor Red 
            Add-Content -Path $ErrorsFile -Value $formattedMessage
        }
        default { Write-Host $formattedMessage }
    }
    
    Add-Content -Path $DiagnosticsFile -Value $formattedMessage
}

function Test-CommandExists {
    param ($command)
    
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    
    try {
        if (Get-Command $command) {
            return $true
        }
    }
    catch {
        return $false
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
}

# Start diagnostics
Write-Diagnostic "Starting RabbitMQ Troubleshooting Script"
Write-Diagnostic "Results will be saved to $DiagnosticsFile"
Write-Diagnostic "Errors will be saved to $ErrorsFile"
Write-Diagnostic "==========================================="

# Check 1: Verify RabbitMQ and Erlang installations
Write-Diagnostic "Checking RabbitMQ and Erlang installations..." "INFO"

$rabbitPathExists = Test-Path $RabbitMQInstallPath
$erlangPathExists = Test-Path $ErlangInstallPath

if ($rabbitPathExists) {
    Write-Diagnostic "RabbitMQ installation found at $RabbitMQInstallPath" "SUCCESS"
} else {
    Write-Diagnostic "RabbitMQ installation NOT found at $RabbitMQInstallPath" "ERROR"
    Write-Diagnostic "Please check if RabbitMQ is installed or provide correct path" "ERROR"
}

if ($erlangPathExists) {
    Write-Diagnostic "Erlang installation found at $ErlangInstallPath" "SUCCESS"
} else {
    Write-Diagnostic "Erlang installation NOT found at $ErlangInstallPath" "WARNING"
    Write-Diagnostic "Please check if Erlang is installed or provide correct path" "WARNING"
}

# Check 2: RabbitMQ Service Status
Write-Diagnostic "Checking RabbitMQ service status..." "INFO"

$rabbitService = Get-Service -Name RabbitMQ -ErrorAction SilentlyContinue

if ($rabbitService) {
    Write-Diagnostic "RabbitMQ service found, current status: $($rabbitService.Status)" "INFO"
    
    if ($rabbitService.Status -eq "Running") {
        Write-Diagnostic "RabbitMQ service is running properly" "SUCCESS"
    } else {
        Write-Diagnostic "RabbitMQ service is NOT running (Status: $($rabbitService.Status))" "ERROR"
        
        # Try to get more information about why service isn't running
        try {
            $eventLogs = Get-WinEvent -FilterHashtable @{
                LogName = 'Application'
                ProviderName = 'RabbitMQ'
            } -MaxEvents 5 -ErrorAction SilentlyContinue
            
            if ($eventLogs) {
                Write-Diagnostic "Recent RabbitMQ event logs:" "INFO"
                foreach ($log in $eventLogs) {
                    Write-Diagnostic "  $($log.TimeCreated) [ID: $($log.Id)]: $($log.Message)" "INFO"
                }
            }
        } catch {
            Write-Diagnostic "Could not retrieve RabbitMQ event logs" "WARNING"
        }
    }
} else {
    Write-Diagnostic "RabbitMQ service NOT found on this system" "ERROR"
    Write-Diagnostic "Check if RabbitMQ is installed correctly or if the service has a different name" "ERROR"
}

# Check 3: RabbitMQ Log Files
Write-Diagnostic "Checking RabbitMQ log files..." "INFO"

$possibleLogPaths = @(
    "$RabbitMQInstallPath\var\log\rabbitmq",
    "$env:APPDATA\RabbitMQ\log",
    "C:\Windows\System32\config\systemprofile\AppData\Roaming\RabbitMQ\log"
)

$logFilesFound = $false

foreach ($logPath in $possibleLogPaths) {
    if (Test-Path $logPath) {
        $logFiles = Get-ChildItem -Path $logPath -Filter *.log
        
        if ($logFiles.Count -gt 0) {
            $logFilesFound = $true
            Write-Diagnostic "Found RabbitMQ log files in: $logPath" "SUCCESS"
            
            # Copy the most recent log files to output directory
            $recentLogs = $logFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 3
            
            foreach ($log in $recentLogs) {
                $logContent = Get-Content -Path $log.FullName -Tail 50
                $targetLogFile = Join-Path -Path $LogOutputPath -ChildPath $log.Name
                
                Write-Diagnostic "Copying recent log file: $($log.Name)" "INFO"
                $logContent | Out-File -FilePath $targetLogFile
                
                # Check for common errors in logs
                $errorPatterns = @(
                    "ERROR",
                    "connection failure",
                    "CRASH REPORT",
                    "econnrefused",
                    "authentication failure",
                    "permission denied",
                    "timeout"
                )
                
                foreach ($pattern in $errorPatterns) {
                    $errors = $logContent | Select-String -Pattern $pattern -SimpleMatch
                    if ($errors) {
                        foreach ($error in $errors) {
                            Write-Diagnostic "Found potential issue in $($log.Name): $($error.Line)" "ERROR"
                        }
                    }
                }
            }
        }
    }
}

if (-not $logFilesFound) {
    Write-Diagnostic "Could not find RabbitMQ log files in expected locations" "WARNING"
}

# Check 4: RabbitMQ Configuration Files
Write-Diagnostic "Checking RabbitMQ configuration files..." "INFO"

$configPaths = @(
    "$RabbitMQInstallPath\etc\rabbitmq\rabbitmq.conf",
    "$RabbitMQInstallPath\etc\rabbitmq\advanced.config",
    "$env:APPDATA\RabbitMQ\rabbitmq.conf"
)

$configFilesFound = $false

foreach ($configPath in $configPaths) {
    if (Test-Path $configPath) {
        $configFilesFound = $true
        Write-Diagnostic "Found RabbitMQ config file: $configPath" "SUCCESS"
        
        # Copy config file to output directory
        $configFileName = Split-Path $configPath -Leaf
        $targetConfigFile = Join-Path -Path $LogOutputPath -ChildPath $configFileName
        
        Copy-Item -Path $configPath -Destination $targetConfigFile
        Write-Diagnostic "Copied configuration file to $targetConfigFile" "INFO"
    }
}

if (-not $configFilesFound) {
    Write-Diagnostic "Could not find RabbitMQ configuration files in expected locations" "WARNING"
    Write-Diagnostic "RabbitMQ might be running with default configuration" "INFO"
}

# Check 5: RabbitMQ Management Plugin Status
Write-Diagnostic "Checking RabbitMQ management plugin..." "INFO"

$rabbitctlCmd = "$RabbitMQInstallPath\sbin\rabbitmqctl.bat"

if (Test-Path $rabbitctlCmd) {
    try {
        $pluginsList = & $rabbitctlCmd list_plugins 2>&1
        $managementEnabled = $pluginsList | Where-Object { $_ -match "rabbitmq_management.*\[E" }
        
        if ($managementEnabled) {
            Write-Diagnostic "RabbitMQ management plugin is enabled" "SUCCESS"
            
            # Test management web interface
            $mgmtUri = "http://localhost:15672"
            try {
                $webRequest = Invoke-WebRequest -Uri $mgmtUri -UseBasicParsing
                if ($webRequest.StatusCode -eq 200) {
                    Write-Diagnostic "RabbitMQ management web interface is accessible at $mgmtUri" "SUCCESS"
                }
            } catch {
                Write-Diagnostic "RabbitMQ management web interface is NOT accessible at $mgmtUri" "ERROR"
                Write-Diagnostic "Error: $($_.Exception.Message)" "ERROR"
            }
        } else {
            Write-Diagnostic "RabbitMQ management plugin is NOT enabled" "WARNING"
            Write-Diagnostic "To enable it, run: rabbitmq-plugins enable rabbitmq_management" "INFO"
        }
    } catch {
        Write-Diagnostic "Failed to check RabbitMQ plugins status" "ERROR"
        Write-Diagnostic "Error: $($_.Exception.Message)" "ERROR"
    }
} else {
    Write-Diagnostic "Could not find rabbitmqctl at $rabbitctlCmd" "ERROR"
}

# Check 6: RabbitMQ Network Ports
Write-Diagnostic "Checking RabbitMQ network ports..." "INFO"

$rabbitPorts = @(
    @{Port = 5672; Description = "AMQP" },
    @{Port = 15672; Description = "Management Plugin" },
    @{Port = 25672; Description = "Inter-node communication" },
    @{Port = 4369; Description = "EPMD (Erlang Port Mapper Daemon)" }
)

foreach ($portInfo in $rabbitPorts) {
    $port = $portInfo.Port
    $description = $portInfo.Description
    
    try {
        $tcpConnection = New-Object System.Net.Sockets.TcpClient
        $connection = $tcpConnection.BeginConnect("localhost", $port, $null, $null)
        $wait = $connection.AsyncWaitHandle.WaitOne(1000, $false)
        
        if ($wait -and $tcpConnection.Connected) {
            Write-Diagnostic "Port $port ($description) is open and accessible" "SUCCESS"
        } else {
            Write-Diagnostic "Port $port ($description) is NOT accessible" "ERROR"
        }
        
        $tcpConnection.Close()
    } catch {
        Write-Diagnostic "Error checking port $port ($description): $($_.Exception.Message)" "ERROR"
    }
}

# Check 7: System Resources
Write-Diagnostic "Checking system resources..." "INFO"

# Memory check
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
$operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
$totalMemoryGB = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
$freeMemoryGB = [math]::Round($operatingSystem.FreePhysicalMemory / 1MB, 2)
$memoryUsedPercent = [math]::Round(100 - (($operatingSystem.FreePhysicalMemory / 1KB) / ($computerSystem.TotalPhysicalMemory / 1MB) * 100), 2)

Write-Diagnostic "Total System Memory: $totalMemoryGB GB" "INFO"
Write-Diagnostic "Free Memory: $freeMemoryGB GB ($memoryUsedPercent% used)" "INFO"

if ($memoryUsedPercent -gt 90) {
    Write-Diagnostic "MEMORY ISSUE: System is critically low on memory (>90% used)" "ERROR"
} elseif ($memoryUsedPercent -gt 80) {
    Write-Diagnostic "MEMORY WARNING: System is running low on memory (>80% used)" "WARNING"
} else {
    Write-Diagnostic "Memory usage is within acceptable limits" "SUCCESS"
}

# Disk space check
$drive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
$diskSpaceTotal = [math]::Round($drive.Size / 1GB, 2)
$diskSpaceFree = [math]::Round($drive.FreeSpace / 1GB, 2)
$diskSpaceUsedPercent = [math]::Round(100 - (($drive.FreeSpace / $drive.Size) * 100), 2)

Write-Diagnostic "Total Disk Space (C:): $diskSpaceTotal GB" "INFO"
Write-Diagnostic "Free Disk Space (C:): $diskSpaceFree GB ($diskSpaceUsedPercent% used)" "INFO"

if ($diskSpaceUsedPercent -gt 90) {
    Write-Diagnostic "DISK SPACE ISSUE: System is critically low on disk space (>90% used)" "ERROR"
} elseif ($diskSpaceUsedPercent -gt 80) {
    Write-Diagnostic "DISK SPACE WARNING: System is running low on disk space (>80% used)" "WARNING"
} else {
    Write-Diagnostic "Disk space usage is within acceptable limits" "SUCCESS"
}

# Check 8: RabbitMQ Status Details
if (Test-Path $rabbitctlCmd) {
    Write-Diagnostic "Getting detailed RabbitMQ status..." "INFO"
    
    try {
        $statusOutput = & $rabbitctlCmd status 2>&1
        $statusFile = Join-Path -Path $LogOutputPath -ChildPath "rabbitmq_status.txt"
        $statusOutput | Out-File -FilePath $statusFile
        Write-Diagnostic "RabbitMQ status information saved to $statusFile" "SUCCESS"
        
        # Process status output to extract key metrics
        $memoryUsage = $statusOutput | Select-String -Pattern "memory,total" | ForEach-Object { $_ -replace '\D+(\d+)\D+', '$1' }
        $processesTotal = $statusOutput | Select-String -Pattern "process_count,total" | ForEach-Object { $_ -replace '\D+(\d+)\D+', '$1' }
        $fileDescriptors = $statusOutput | Select-String -Pattern "file_descriptors,total_used" | ForEach-Object { $_ -replace '\D+(\d+)\D+', '$1' }
        
        if ($memoryUsage) {
            $memoryUsageMB = [math]::Round([int]$memoryUsage / 1MB, 2)
            Write-Diagnostic "RabbitMQ Memory Usage: $memoryUsageMB MB" "INFO"
        }
        
        if ($processesTotal) {
            Write-Diagnostic "RabbitMQ Process Count: $processesTotal" "INFO"
        }
        
        if ($fileDescriptors) {
            Write-Diagnostic "RabbitMQ File Descriptors Used: $fileDescriptors" "INFO"
        }
    } catch {
        Write-Diagnostic "Failed to retrieve RabbitMQ status" "ERROR"
        Write-Diagnostic "Error: $($_.Exception.Message)" "ERROR"
    }
    
    # Check queues
    try {
        Write-Diagnostic "Checking RabbitMQ queues..." "INFO"
        $queueOutput = & $rabbitctlCmd list_queues name messages consumers state 2>&1
        $queueFile = Join-Path -Path $LogOutputPath -ChildPath "rabbitmq_queues.txt"
        $queueOutput | Out-File -FilePath $queueFile
        Write-Diagnostic "RabbitMQ queue information saved to $queueFile" "SUCCESS"
        
        # Look for problematic queues
        $problemQueues = $queueOutput | Where-Object { 
            $_ -match "messages\s+\d{3,}" -or 
            $_ -match "idle" 
        }
        
        if ($problemQueues) {
            Write-Diagnostic "Potential queue issues found:" "WARNING"
            foreach ($queue in $problemQueues) {
                Write-Diagnostic "  $queue" "WARNING"
            }
        } else {
            Write-Diagnostic "No obvious issues found in queues" "SUCCESS"
        }
    } catch {
        Write-Diagnostic "Failed to retrieve RabbitMQ queue information" "ERROR"
        Write-Diagnostic "Error: $($_.Exception.Message)" "ERROR"
    }
    
    # Check connections
    try {
        Write-Diagnostic "Checking RabbitMQ connections..." "INFO"
        $connectionOutput = & $rabbitctlCmd list_connections user client_properties 2>&1
        $connectionFile = Join-Path -Path $LogOutputPath -ChildPath "rabbitmq_connections.txt"
        $connectionOutput | Out-File -FilePath $connectionFile
        Write-Diagnostic "RabbitMQ connection information saved to $connectionFile" "SUCCESS"
        
        $connectionCount = ($connectionOutput | Measure-Object).Count - 1
        if ($connectionCount -lt 0) { $connectionCount = 0 }
        
        Write-Diagnostic "RabbitMQ active connections: $connectionCount" "INFO"
    } catch {
        Write-Diagnostic "Failed to retrieve RabbitMQ connection information" "ERROR"
        Write-Diagnostic "Error: $($_.Exception.Message)" "ERROR"
    }
}

# Check 9: Network DNS Configuration
Write-Diagnostic "Checking network DNS configuration..." "INFO"

try {
    $computerName = $env:COMPUTERNAME
    $dnsHostname = [System.Net.Dns]::GetHostName()
    $dnsEntries = [System.Net.Dns]::GetHostAddresses($dnsHostname) | ForEach-Object { $_.IPAddressToString }
    
    Write-Diagnostic "Computer Name: $computerName" "INFO"
    Write-Diagnostic "DNS Hostname: $dnsHostname" "INFO"
    Write-Diagnostic "IP Addresses:" "INFO"
    
    foreach ($ip in $dnsEntries) {
        Write-Diagnostic "  $ip" "INFO"
    }
    
    if ($computerName -ne $dnsHostname) {
        Write-Diagnostic "WARNING: Computer name and DNS hostname do not match" "WARNING"
        Write-Diagnostic "This may cause issues with RabbitMQ node names" "WARNING"
    }
    
    # Check hosts file
    $hostsFile = "$env:windir\System32\drivers\etc\hosts"
    if (Test-Path $hostsFile) {
        $hostsContent = Get-Content $hostsFile | Where-Object { $_ -notmatch "^\s*#" -and $_ -match "\S" }
        
        if ($hostsContent) {
            Write-Diagnostic "Host file entries that might affect RabbitMQ:" "INFO"
            foreach ($line in $hostsContent) {
                Write-Diagnostic "  $line" "INFO"
            }
        }
    }
} catch {
    Write-Diagnostic "Failed to check DNS configuration" "ERROR"
    Write-Diagnostic "Error: $($_.Exception.Message)" "ERROR"
}

# Final summary
Write-Diagnostic "==========================================="
$errorCount = (Get-Content -Path $ErrorsFile -ErrorAction SilentlyContinue | Measure-Object).Count

if ($errorCount -gt 0) {
    Write-Diagnostic "Troubleshooting completed with $errorCount potential issues identified." "WARNING"
    Write-Diagnostic "Please review the detailed error log at: $ErrorsFile" "WARNING"
} else {
    Write-Diagnostic "Troubleshooting completed. No critical issues were found." "SUCCESS"
}

Write-Diagnostic "Full diagnostic report available at: $DiagnosticsFile" "INFO"
Write-Diagnostic "==========================================="

Write-Host ""
Write-Host "RabbitMQ Troubleshooting completed!" -ForegroundColor Green
Write-Host "Results saved to: $LogOutputPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "If you're still experiencing issues, review the output files and try these additional steps:" -ForegroundColor Yellow
Write-Host "1. Restart the RabbitMQ service: Restart-Service RabbitMQ" -ForegroundColor Yellow
Write-Host "2. Check for firewalls blocking RabbitMQ ports (4369, 5672, 15672, 25672)" -ForegroundColor Yellow
Write-Host "3. Verify Erlang and RabbitMQ versions are compatible" -ForegroundColor Yellow
Write-Host "4. Check for disk space and memory constraints" -ForegroundColor Yellow
Write-Host "5. Review application logs for connection errors" -ForegroundColor Yellow