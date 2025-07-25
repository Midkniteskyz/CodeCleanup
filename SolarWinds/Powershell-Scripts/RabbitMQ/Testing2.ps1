# Define target servers (replace with your actual server names or IPs)
$targets = @(
    "MainPollingEngine",    # Replace with your main polling engine
    "OrionServer01",        # Replace with actual Orion server names
    "HA-Primary",
    "HA-Secondary"
)

# Define ports to test
$ports = @(
    @{ Port = 5671; Description = "AMQP/TLS (Main Polling Engine <-> Orion Servers)" },
    @{ Port = 25672; Description = "Erlang Distribution (RabbitMQ Clustering)" },
    @{ Port = 4369; Description = "EPMD (RabbitMQ Clustering)" }
)

# Create results array
$results = @()

# Function to check RabbitMQ service status
function Get-ServiceStatus {
    param (
        [string]$ComputerName,
        [string]$ServiceName
    )
    try {
        $service = Get-Service -ComputerName $ComputerName -Name $ServiceName -ErrorAction Stop
        return $service.Status
    } catch {
        return "Service not found"
    }
}

# Function to analyze RabbitMQ logs for errors
function Analyze-RabbitMQLogs {
    param (
        [string]$ComputerName,
        [string]$LogPath
    )
    $session = New-PSSession -ComputerName $ComputerName
    $errors = Invoke-Command -Session $session -ScriptBlock {
        param ($LogPath)
        if (Test-Path $LogPath) {
            Select-String -Path $LogPath -Pattern "ERROR|CRITICAL|failed" -SimpleMatch
        } else {
            "Log file not found"
        }
    } -ArgumentList $LogPath
    Remove-PSSession -Session $session
    return $errors
}

# Loop through targets and perform checks
foreach ($target in $targets) {
    foreach ($portInfo in $ports) {
        $test = Test-NetConnection -ComputerName $target -Port $portInfo.Port -WarningAction SilentlyContinue

        $results += [PSCustomObject]@{
            Target           = $target
            Port             = $portInfo.Port
            Description      = $portInfo.Description
            TcpTestSucceeded = $test.TcpTestSucceeded
            RemoteAddress    = $test.RemoteAddress
            Message          = if ($test.TcpTestSucceeded) { "Open" } else { "Closed or Unreachable" }
        }
    }

    # Check RabbitMQ service status
    $serviceStatus = Get-ServiceStatus -ComputerName $target -ServiceName "RabbitMQ"
    $results += [PSCustomObject]@{
        Target      = $target
        Port        = "N/A"
        Description = "RabbitMQ Service Status"
        TcpTestSucceeded = $null
        RemoteAddress = $null
        Message     = $serviceStatus
    }

    # Analyze RabbitMQ logs for errors
    $logPath = "C:\ProgramData\SolarWinds\Orion\RabbitMQ\log\rabbitmq.log" # Adjust path as necessary
    $logErrors = Analyze-RabbitMQLogs -ComputerName $target -LogPath $logPath
    if ($logErrors) {
        foreach ($error in $logErrors) {
            $results += [PSCustomObject]@{
                Target           = $target
                Port             = "N/A"
                Description      = "RabbitMQ Log Error"
                TcpTestSucceeded = $null
                RemoteAddress    = $null
                Message          = $error
            }
        }
    } else {
        $results += [PSCustomObject]@{
            Target           = $target
            Port             = "N/A"
            Description      = "RabbitMQ Log Analysis"
            TcpTestSucceeded = $null
            RemoteAddress    = $null
            Message          = "No errors found"
        }
    }
}

# Show results
$results | Out-GridView -Title "RabbitMQ Diagnostics"
