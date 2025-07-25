param(
    [Parameter(Mandatory=$true)]
    [string[]]$ComputerNames,
    
    [Parameter(Mandatory=$false)]
    [int]$PingCount = 2,
    
    [Parameter(Mandatory=$false)]
    [int]$SNMPPort = 161,
    
    [Parameter(Mandatory=$false)]
    [int]$WMIPort = 135,
    
    [Parameter(Mandatory=$false)]
    [int]$Timeout = 3000
)

# Create array to store results
$results = @()

# Function to test if a port is open
function Test-PortConnection {
    param(
        [string]$ComputerName,
        [int]$Port,
        [int]$Timeout
    )
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $result = $tcpClient.BeginConnect($ComputerName, $Port, $null, $null)
        $success = $result.AsyncWaitHandle.WaitOne($Timeout, $false)
        
        if ($success) {
            # Make sure the connection was actually established
            if ($tcpClient.Connected) {
                $tcpClient.EndConnect($result)
                $tcpClient.Close()
                return $true
            }
        }
        
        if ($tcpClient.Connected) { $tcpClient.Close() }
        return $false
    }
    catch {
        return $false
    }
}

foreach ($computer in $ComputerNames) {
    Write-Host "Testing connection to $computer..." -ForegroundColor Cyan
    
    # Initialize result object
    $result = [PSCustomObject]@{
        Hostname = $computer
        IPAddress = "N/A"
        PingSuccess = $false
        PingResponseTime = "N/A"
        PacketsLost = "N/A"
        SNMPPortOpen = $false
        WMIPortOpen = $false
    }
    
    # Test ping
    try {
        $pingResult = Test-Connection -ComputerName $computer -Count $PingCount -ErrorAction Stop
        
        if ($pingResult) {
            $result.PingSuccess = $true
            $result.IPAddress = $pingResult[0].Address.IPAddressToString
            $avgResponseTime = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
            $result.PingResponseTime = "$([math]::Round($avgResponseTime, 2)) ms"
            
            $packetsSent = $PingCount
            $packetsReceived = ($pingResult | Measure-Object).Count
            $packetsLost = $packetsSent - $packetsReceived
            $packetLossPercentage = ($packetsLost / $packetsSent) * 100
            $result.PacketsLost = "$packetsLost/$packetsSent ($([math]::Round($packetLossPercentage, 1))%)"
        }
    }
    catch {
        Write-Host "  Ping failed: $_" -ForegroundColor Red
        $result.PingSuccess = $false
        $result.PacketsLost = "$PingCount/$PingCount (100%)"
        
        # Try to resolve IP address even if ping fails
        try {
            $result.IPAddress = [System.Net.Dns]::GetHostAddresses($computer)[0].IPAddressToString
        }
        catch {
            $result.IPAddress = "Unable to resolve"
        }
    }
    
    # Ensure we have an IP address to test ports against
    $ipToTest = $result.IPAddress
    if ($ipToTest -eq "N/A" -or $ipToTest -eq "Unable to resolve") {
        $ipToTest = $computer # Try using hostname directly if IP resolution failed
    }
    
    # Test SNMP port
    if ($ipToTest -ne "Unable to resolve") {
        if (Test-PortConnection -ComputerName $ipToTest -Port $SNMPPort -Timeout $Timeout) {
            $result.SNMPPortOpen = $true
            Write-Host "  SNMP port $SNMPPort is open" -ForegroundColor Green
        } else {
            Write-Host "  SNMP port $SNMPPort is closed or filtered" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Cannot test SNMP port: Unable to resolve hostname" -ForegroundColor Red
    }
    
    # Test WMI port
    if ($ipToTest -ne "Unable to resolve") {
        if (Test-PortConnection -ComputerName $ipToTest -Port $WMIPort -Timeout $Timeout) {
            $result.WMIPortOpen = $true
            Write-Host "  WMI port $WMIPort is open" -ForegroundColor Green
        } else {
            Write-Host "  WMI port $WMIPort is closed or filtered" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Cannot test WMI port: Unable to resolve hostname" -ForegroundColor Red
    }
    
    # Add result to collection
    $results += $result
}

# Display results in a formatted table
$results | Format-Table -AutoSize

# Return results for pipeline usage
return $results