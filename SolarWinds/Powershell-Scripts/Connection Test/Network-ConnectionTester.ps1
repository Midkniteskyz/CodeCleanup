#Requires -Version 3.0
<#
.SYNOPSIS
    Tests network connectivity to specified computers using ping, port testing, and more.

.DESCRIPTION
    This script tests connectivity to one or more computers using ping and port checks.
    It can test SNMP, WMI, and other specified ports to validate network connectivity.
    Results are displayed in a color-coded, easy-to-read format.

.PARAMETER ComputerNames
    One or more computer names or IP addresses to test connectivity to.

.PARAMETER InputFile
    Path to a text file containing computer names or IP addresses (one per line).

.PARAMETER PingCount
    Number of ping packets to send to each computer. Default is 2.

.PARAMETER TestSNMP
    If specified, tests if the SNMP port is open.

.PARAMETER TestWMI
    If specified, tests if the WMI port is open.

.PARAMETER CustomPorts
    Array of custom ports to test.

.PARAMETER SNMPPort
    SNMP port to test. Default is 161.

.PARAMETER WMIPort
    WMI port to test. Default is 135.

.PARAMETER Timeout
    Timeout in milliseconds for port connection tests. Default is 3000.

.PARAMETER OutputFile
    Path to save results to a CSV file.

.EXAMPLE
    .\Network-ConnectionTester.ps1 -ComputerNames Server01, Server02
    Tests connectivity to Server01 and Server02 using default settings.

.EXAMPLE
    .\Network-ConnectionTester.ps1 -InputFile .\servers.txt -TestSNMP -TestWMI
    Tests connectivity to all servers listed in servers.txt, including SNMP and WMI port tests.

.EXAMPLE
    .\Network-ConnectionTester.ps1 -ComputerNames 192.168.1.10 -CustomPorts 80,443,3389 -OutputFile results.csv
    Tests connectivity to 192.168.1.10, custom ports 80, 443, and 3389, and saves results to results.csv.
#>

[CmdletBinding(DefaultParameterSetName="ComputerList")]
param(
    [Parameter(Mandatory=$true, ParameterSetName="ComputerList", Position=0)]
    [string[]]$ComputerNames,
    
    [Parameter(Mandatory=$true, ParameterSetName="FromFile")]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [int]$PingCount = 2,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestSNMP,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestWMI,
    
    [Parameter(Mandatory=$false)]
    [int[]]$CustomPorts,
    
    [Parameter(Mandatory=$false)]
    [int]$SNMPPort = 161,
    
    [Parameter(Mandatory=$false)]
    [int]$WMIPort = 135,
    
    [Parameter(Mandatory=$false)]
    [int]$Timeout = 3000,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

# Helper function to write colored text in the console
function Write-ColorOutput {
    param(
        [string]$Text,
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White
    )
    
    $originalForegroundColor = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Text
    $host.UI.RawUI.ForegroundColor = $originalForegroundColor
}

# Helper function to check if a port is open
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

# Function to test a computer's connectivity
function Test-ComputerConnectivity {
    param(
        [string]$ComputerName,
        [int]$PingCount,
        [int]$SNMPPort,
        [int]$WMIPort,
        [int[]]$CustomPorts,
        [int]$Timeout,
        [bool]$CheckSNMP,
        [bool]$CheckWMI
    )
    
    # Initialize result object
    $result = [PSCustomObject]@{
        Hostname = $ComputerName
        IPAddress = "N/A"
        PingSuccess = $false
        PingResponseTime = "N/A"
        PacketsLost = "N/A"
        SNMPStatus = "Not Tested"
        WMIStatus = "Not Tested"
        CustomPortsStatus = @{}
    }
    
    # Test ping
    try {
        $pingResult = Test-Connection -ComputerName $ComputerName -Count $PingCount -ErrorAction Stop
        
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
        $result.PingSuccess = $false
        $result.PacketsLost = "$PingCount/$PingCount (100%)"
        
        # Try to resolve IP address even if ping fails
        try {
            $result.IPAddress = [System.Net.Dns]::GetHostAddresses($ComputerName)[0].IPAddressToString
        }
        catch {
            $result.IPAddress = "Unable to resolve"
        }
    }
    
    # Ensure we have an IP address to test ports against
    $ipToTest = $result.IPAddress
    if ($ipToTest -eq "N/A" -or $ipToTest -eq "Unable to resolve") {
        $ipToTest = $ComputerName # Try using hostname directly if IP resolution failed
    }
    
    # Test SNMP port if requested
    if ($CheckSNMP -and $ipToTest -ne "Unable to resolve") {
        if (Test-PortConnection -ComputerName $ipToTest -Port $SNMPPort -Timeout $Timeout) {
            $result.SNMPStatus = "Open"
        } else {
            $result.SNMPStatus = "Closed/Filtered"
        }
    }
    
    # Test WMI port if requested
    if ($CheckWMI -and $ipToTest -ne "Unable to resolve") {
        if (Test-PortConnection -ComputerName $ipToTest -Port $WMIPort -Timeout $Timeout) {
            $result.WMIStatus = "Open"
        } else {
            $result.WMIStatus = "Closed/Filtered"
        }
    }
    
    # Test custom ports if provided
    if ($CustomPorts -and $CustomPorts.Count -gt 0 -and $ipToTest -ne "Unable to resolve") {
        foreach ($port in $CustomPorts) {
            if (Test-PortConnection -ComputerName $ipToTest -Port $port -Timeout $Timeout) {
                $result.CustomPortsStatus[$port] = "Open"
            } else {
                $result.CustomPortsStatus[$port] = "Closed/Filtered"
            }
        }
    }
    
    return $result
}

# Display script banner
Write-ColorOutput "Network Connection Tester" -ForegroundColor Cyan
Write-ColorOutput "======================" -ForegroundColor Cyan
Write-ColorOutput ""

# Get computer names from file if specified
if ($PSCmdlet.ParameterSetName -eq "FromFile") {
    try {
        $ComputerNames = Get-Content -Path $InputFile -ErrorAction Stop | Where-Object { $_ -match '\S' }
        Write-ColorOutput "Loaded $($ComputerNames.Count) computer names from $InputFile" -ForegroundColor Cyan
    }
    catch {
        Write-ColorOutput "Error reading computer names from file: $_" -ForegroundColor Red
        exit 1
    }
    
    if ($ComputerNames.Count -eq 0) {
        Write-ColorOutput "No valid computer names found in file $InputFile" -ForegroundColor Red
        exit 1
    }
}

# Display configuration summary
Write-ColorOutput "Configuration:" -ForegroundColor Cyan
Write-ColorOutput "  * Testing $($ComputerNames.Count) computers" -ForegroundColor White
Write-ColorOutput "  * Ping count: $PingCount" -ForegroundColor White
if ($TestSNMP) { Write-ColorOutput "  * Testing SNMP port: $SNMPPort" -ForegroundColor White }
if ($TestWMI) { Write-ColorOutput "  * Testing WMI port: $WMIPort" -ForegroundColor White }
if ($CustomPorts -and $CustomPorts.Count -gt 0) { 
    Write-ColorOutput "  * Testing custom ports: $($CustomPorts -join ', ')" -ForegroundColor White 
}
Write-ColorOutput "  * Connection timeout: $Timeout ms" -ForegroundColor White
if ($OutputFile) { Write-ColorOutput "  * Results will be saved to: $OutputFile" -ForegroundColor White }
Write-ColorOutput ""

# Create array to store results
$results = @()

# Test each computer
$totalComputers = $ComputerNames.Count
$currentComputer = 0

foreach ($computer in $ComputerNames) {
    $currentComputer++
    $progressPercentage = [math]::Round(($currentComputer / $totalComputers) * 100)
    
    Write-Progress -Activity "Testing network connectivity" -Status "Computer $currentComputer of $totalComputers : $computer" -PercentComplete $progressPercentage
    
    Write-ColorOutput "`nTesting computer $currentComputer of $totalComputers : $computer" -ForegroundColor Cyan
    
    # Test this computer
    $result = Test-ComputerConnectivity -ComputerName $computer -PingCount $PingCount -SNMPPort $SNMPPort -WMIPort $WMIPort -CustomPorts $CustomPorts -Timeout $Timeout -CheckSNMP $TestSNMP -CheckWMI $TestWMI
    
    # Display result for this computer
    Write-ColorOutput "  * IP Address: $($result.IPAddress)" -ForegroundColor White
    
    if ($result.PingSuccess) {
        Write-ColorOutput "  * Ping: Success" -ForegroundColor Green
        Write-ColorOutput "  * Avg Response Time: $($result.PingResponseTime)" -ForegroundColor White
        Write-ColorOutput "  * Packets Lost: $($result.PacketsLost)" -ForegroundColor White
    }
    else {
        Write-ColorOutput "  * Ping: Failed" -ForegroundColor Red
        Write-ColorOutput "  * Packets Lost: $($result.PacketsLost)" -ForegroundColor Red
    }
    
    if ($TestSNMP) {
        if ($result.SNMPStatus -eq "Open") {
            Write-ColorOutput "  * SNMP Port ($SNMPPort): Open" -ForegroundColor Green
        }
        else {
            Write-ColorOutput "  * SNMP Port ($SNMPPort): $($result.SNMPStatus)" -ForegroundColor Yellow
        }
    }
    
    if ($TestWMI) {
        if ($result.WMIStatus -eq "Open") {
            Write-ColorOutput "  * WMI Port ($WMIPort): Open" -ForegroundColor Green
        }
        else {
            Write-ColorOutput "  * WMI Port ($WMIPort): $($result.WMIStatus)" -ForegroundColor Yellow
        }
    }
    
    if ($CustomPorts -and $CustomPorts.Count -gt 0) {
        Write-ColorOutput "  * Custom Ports:" -ForegroundColor White
        foreach ($port in $CustomPorts) {
            $status = $result.CustomPortsStatus[$port]
            if ($status -eq "Open") {
                Write-ColorOutput "    - Port $port : Open" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "    - Port $port : $status" -ForegroundColor Yellow
            }
        }
    }
    
    # Add result to collection
    $results += $result
}

Write-Progress -Activity "Testing network connectivity" -Completed

# Display summary
Write-ColorOutput "`n`nSummary:" -ForegroundColor Cyan
Write-ColorOutput "========" -ForegroundColor Cyan

$successCount = ($results | Where-Object { $_.PingSuccess -eq $true }).Count
$failCount = $totalComputers - $successCount

Write-ColorOutput "Total computers tested: $totalComputers" -ForegroundColor White
Write-ColorOutput "Successful connections: $successCount" -ForegroundColor $(if ($successCount -gt 0) { "Green" } else { "White" })
Write-ColorOutput "Failed connections: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "White" })

# Export results to CSV if requested
if ($OutputFile) {
    try {
        # Create a simplified version of results suitable for CSV export
        $exportResults = $results | ForEach-Object {
            $item = [PSCustomObject]@{
                Hostname = $_.Hostname
                IPAddress = $_.IPAddress
                PingSuccess = $_.PingSuccess
                PingResponseTime = $_.PingResponseTime
                PacketsLost = $_.PacketsLost
                SNMPStatus = $_.SNMPStatus
                WMIStatus = $_.WMIStatus
            }
            
            # Add custom ports if any
            if ($CustomPorts -and $CustomPorts.Count -gt 0) {
                foreach ($port in $CustomPorts) {
                    $item | Add-Member -MemberType NoteProperty -Name "Port_$port" -Value $_.CustomPortsStatus[$port]
                }
            }
            
            return $item
        }
        
        $exportResults | Export-Csv -Path $OutputFile -NoTypeInformation
        Write-ColorOutput "`nResults successfully exported to $OutputFile" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "`nError exporting results to CSV: $_" -ForegroundColor Red
    }
}

# Return results for pipeline usage
return $results