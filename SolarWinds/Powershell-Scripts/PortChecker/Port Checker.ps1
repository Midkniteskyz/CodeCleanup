# Define the list of ports to check
$ports = @{
    'Outbound' = @(22, 25, 465, 587, 1433, 1434)
    'Inbound' = @(80, 162, 443, 514, 17778)
    'Bi-directional' = @(53, 135, 161, 5671, 17777)
}

# Function to check TCP port
function Test-Port {
    param (
        [string]$IPAddress,
        [int]$Port,
        [string]$Protocol = 'TCP'
    )
    try {
        $socket = New-Object System.Net.Sockets.TcpClient
        $socket.Connect($IPAddress, $Port)
        $socket.Close()
        return $true
    } catch {
        return $false
    }
}

# Function to check UDP port
function Test-UDP {
    param (
        [string]$IPAddress,
        [int]$Port
    )
    try {
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $udpClient.Connect($IPAddress, $Port)
        $udpClient.Close()
        return $true
    } catch {
        return $false
    }
}

# Function to check if a firewall rule exists
function Get-FirewallRuleExists {
    param (
        [string]$Name
    )
    $ruleExists = Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
    return [bool]$ruleExists
}

# Define the server IP address (change this to your server's IP)
$serverIP = '127.0.0.1'

# Prepare an array to store results
$results = @()

# Loop through each category of ports
foreach ($category in $ports.Keys) {
    foreach ($port in $ports[$category]) {
        # Test TCP port
        $tcpResult = Test-Port -IPAddress $serverIP -Port $port
        $tcpStatus = if ($tcpResult) { 'Enabled' } else { 'Not Enabled' }

        # Test UDP port
        $udpResult = Test-UDP -IPAddress $serverIP -Port $port
        $udpStatus = if ($udpResult) { 'Enabled' } else { 'Not Enabled' }

        # Check if firewall rule exists for TCP port
        $tcpRuleName = "Port_$port_TCP"
        $tcpRuleExists = Get-FirewallRuleExists -Name $tcpRuleName
        $tcpRuleStatus = if ($tcpRuleExists) { 'Exists' } else { 'Does Not Exist' }

        # Check if firewall rule exists for UDP port
        $udpRuleName = "Port_$port_UDP"
        $udpRuleExists = Get-FirewallRuleExists -Name $udpRuleName
        $udpRuleStatus = if ($udpRuleExists) { 'Exists' } else { 'Does Not Exist' }

        # Add result to the array
        $results += [PSCustomObject]@{
            'Category' = $category
            'Port' = $port
            'TCP' = $tcpStatus
            'TCP Rule' = $tcpRuleStatus
            'UDP' = $udpStatus
            'UDP Rule' = $udpRuleStatus
        }
    }
}

# Display results in Out-GridView
$results | Out-GridView -Title "Port Check Results" -PassThru
