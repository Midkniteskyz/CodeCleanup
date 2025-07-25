# Define target servers (edit these with your actual server names or IPs)
$targets = @(
    "MainPollingEngine",    # Replace with your main polling engine
    "OrionServer01"         # Replace with actual Orion server names
)

# Define ports to test
$ports = @(
    @{ Port = 5671; Description = "AMQP/TLS (Main Polling Engine <-> Orion Servers)" },
    @{ Port = 25672; Description = "Erlang Distribution (RabbitMQ Clustering)" },
    @{ Port = 4369; Description = "EPMD (RabbitMQ Clustering)" }
)

# Create results array
$results = @()

# Loop through targets and ports
foreach ($target in $targets) {
    foreach ($portInfo in $ports) {
        $test = Test-NetConnection -ComputerName $target -Port $portInfo.Port -WarningAction SilentlyContinue

        $results += [PSCustomObject]@{
            Target      = $target
            Port        = $portInfo.Port
            Description = $portInfo.Description
            TcpTestSucceeded = $test.TcpTestSucceeded
            RemoteAddress = $test.RemoteAddress
            Message     = if ($test.TcpTestSucceeded) { "Open" } else { "Closed or Unreachable" }
        }
    }
}

# Show results
$results | Out-GridView -Title "RabbitMQ Port Connectivity Check"


<#
Fix
Get-NetFirewallRule | Where-Object { $_.Enabled -eq "True" -and $_.Direction -eq "Inbound" -and $_.Action -eq "Allow" } | Select Name, DisplayName, Description, Direction, Action

New-NetFirewallRule -DisplayName "Allow RabbitMQ 5671" -Direction Inbound -Protocol TCP -LocalPort 5671 -Action Allow
New-NetFirewallRule -DisplayName "Allow RabbitMQ 4369" -Direction Inbound -Protocol TCP -LocalPort 4369 -Action Allow

netstat -ano | findstr ":5671"
netstat -ano | findstr ":4369"
#>