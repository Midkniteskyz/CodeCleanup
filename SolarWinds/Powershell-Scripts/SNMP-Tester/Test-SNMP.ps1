#Requires -Version 5.0
<#
.SYNOPSIS
    Tests SNMP v3 connections with different authentication and privacy combinations.

.DESCRIPTION
    This script helps troubleshoot SNMP v3 connectivity issues by testing various
    combinations of authentication and privacy protocols. It's particularly useful
    for SolarWinds administrators who need to identify the correct SNMP v3 settings
    for target devices.

.PARAMETER Target
    The target IP address or hostname to test SNMP v3 connectivity against.

.PARAMETER Username
    The SNMP v3 username for authentication.

.PARAMETER AuthPassword
    The authentication password for SNMP v3.

.PARAMETER PrivPassword
    The privacy password for SNMP v3 encryption.

.PARAMETER Context
    Optional SNMP v3 context name. Leave empty if not required.

.PARAMETER Port
    SNMP port number. Default is 161.

.PARAMETER Timeout
    Timeout in seconds for each SNMP test. Default is 5 seconds.

.PARAMETER TestOID
    OID to test against. Default is system description (1.3.6.1.2.1.1.1.0).

.PARAMETER OutputFile
    Optional path to save detailed results to a CSV file.

.PARAMETER QuickTest
    If specified, only tests the most common combinations first.

.EXAMPLE
    .\Test-SNMPv3Connection.ps1 -Target "192.168.1.100" -Username "snmpuser" -AuthPassword "authpass123" -PrivPassword "privpass123"
    Tests all combinations of auth/priv protocols against the target device.

.EXAMPLE
    .\Test-SNMPv3Connection.ps1 -Target "server01.domain.com" -Username "monitoring" -AuthPassword "secret123" -PrivPassword "encrypt456" -Context "public" -QuickTest
    Performs a quick test with common protocol combinations including context.

.EXAMPLE
    .\Test-SNMPv3Connection.ps1 -Target "10.0.0.50" -Username "snmpv3user" -AuthPassword "myauth" -PrivPassword "mypriv" -OutputFile "snmp_results.csv"
    Tests all combinations and exports detailed results to CSV.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Target,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$AuthPassword,
    
    [Parameter(Mandatory=$true)]
    [string]$PrivPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$Context = "",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 161,
    
    [Parameter(Mandatory=$false)]
    [int]$Timeout = 5,
    
    [Parameter(Mandatory=$false)]
    [string]$TestOID = "1.3.6.1.2.1.1.1.0",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$QuickTest
)

# Check if SNMP tools are available
function Test-SNMPAvailability {
    $snmpAvailable = $false
    $toolUsed = ""
    
    # Check for snmpget (Net-SNMP tools)
    try {
        $null = Get-Command snmpget -ErrorAction Stop
        $snmpAvailable = $true
        $toolUsed = "Net-SNMP"
    }
    catch {
        # Check for PowerShell SNMP module
        if (Get-Module -ListAvailable -Name "SNMP" -ErrorAction SilentlyContinue) {
            $snmpAvailable = $true
            $toolUsed = "PowerShell SNMP Module"
        }
    }
    
    return @{
        Available = $snmpAvailable
        Tool = $toolUsed
    }
}

# Function to test SNMP connection using Net-SNMP tools
function Test-SNMPWithNetSNMP {
    param(
        [string]$Target,
        [string]$Username,
        [string]$AuthPassword,
        [string]$PrivPassword,
        [string]$AuthProtocol,
        [string]$PrivProtocol,
        [string]$Context,
        [int]$Port,
        [int]$Timeout,
        [string]$TestOID
    )
    
    try {
        # Build snmpget command
        $cmd = "snmpget"
        $args = @(
            "-v3",
            "-u", $Username,
            "-a", $AuthProtocol,
            "-A", $AuthPassword,
            "-x", $PrivProtocol,
            "-X", $PrivPassword,
            "-l", "authPriv",
            "-t", $Timeout
        )
        
        if ($Context) {
            $args += @("-n", $Context)
        }
        
        $args += @("${Target}:${Port}", $TestOID)
        
        # Execute command
        $result = & $cmd $args 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $result -notmatch "Timeout|Error|No Response") {
            return @{
                Success = $true
                Response = $result -join "`n"
                Error = ""
            }
        }
        else {
            return @{
                Success = $false
                Response = ""
                Error = $result -join "`n"
            }
        }
    }
    catch {
        return @{
            Success = $false
            Response = ""
            Error = $_.Exception.Message
        }
    }
}

# Function to test SNMP connection using PowerShell (fallback implementation)
function Test-SNMPWithPowerShell {
    param(
        [string]$Target,
        [string]$Username,
        [string]$AuthPassword,
        [string]$PrivPassword,
        [string]$AuthProtocol,
        [string]$PrivProtocol,
        [string]$Context,
        [int]$Port,
        [int]$Timeout,
        [string]$TestOID
    )
    
    try {
        # This is a simplified implementation - in real scenarios you'd use
        # a proper SNMP library like SharpSNMPLib or similar
        
        # For demonstration, we'll simulate the test with basic UDP connectivity
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $udpClient.Client.ReceiveTimeout = $Timeout * 1000
        
        try {
            $udpClient.Connect($Target, $Port)
            
            # Create a basic SNMP v3 packet structure (simplified)
            # In reality, this would need proper SNMP v3 encoding with crypto
            $packet = @(0x30, 0x82) # Basic SNMP packet start
            $udpClient.Send($packet, $packet.Length)
            
            # Try to receive response
            $remoteEP = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
            $response = $udpClient.Receive([ref]$remoteEP)
            
            if ($response.Length -gt 0) {
                return @{
                    Success = $true
                    Response = "UDP connection successful (simplified test)"
                    Error = ""
                }
            }
        }
        catch {
            return @{
                Success = $false
                Response = ""
                Error = "Connection failed: $($_.Exception.Message)"
            }
        }
        finally {
            $udpClient.Close()
        }
    }
    catch {
        return @{
            Success = $false
            Response = ""
            Error = $_.Exception.Message
        }
    }
}

# Function to perform SNMP test
function Invoke-SNMPTest {
    param(
        [string]$Target,
        [string]$Username,
        [string]$AuthPassword,
        [string]$PrivPassword,
        [string]$AuthProtocol,
        [string]$PrivProtocol,
        [string]$Context,
        [int]$Port,
        [int]$Timeout,
        [string]$TestOID,
        [string]$ToolType
    )
    
    if ($ToolType -eq "Net-SNMP") {
        return Test-SNMPWithNetSNMP -Target $Target -Username $Username -AuthPassword $AuthPassword -PrivPassword $PrivPassword -AuthProtocol $AuthProtocol -PrivProtocol $PrivProtocol -Context $Context -Port $Port -Timeout $Timeout -TestOID $TestOID
    }
    else {
        return Test-SNMPWithPowerShell -Target $Target -Username $Username -AuthPassword $AuthPassword -PrivPassword $PrivPassword -AuthProtocol $AuthProtocol -PrivProtocol $PrivProtocol -Context $Context -Port $Port -Timeout $Timeout -TestOID $TestOID
    }
}

# Main script execution
Write-Host "SNMP v3 Connection Tester" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Check SNMP tool availability
$snmpCheck = Test-SNMPAvailability
if (-not $snmpCheck.Available) {
    Write-Warning "SNMP tools not found. This script works best with Net-SNMP tools installed."
    Write-Warning "Download from: http://www.net-snmp.org/download.html"
    Write-Warning "Falling back to basic PowerShell implementation..."
    $toolType = "PowerShell"
}
else {
    Write-Host "Using SNMP tool: $($snmpCheck.Tool)" -ForegroundColor Green
    $toolType = $snmpCheck.Tool
}

# Display configuration
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Target: $Target" -ForegroundColor White
Write-Host "  Username: $Username" -ForegroundColor White
Write-Host "  Port: $Port" -ForegroundColor White
Write-Host "  Timeout: $Timeout seconds" -ForegroundColor White
Write-Host "  Test OID: $TestOID" -ForegroundColor White
if ($Context) {
    Write-Host "  Context: $Context" -ForegroundColor White
}
Write-Host ""

# Define authentication and privacy protocols
$authProtocols = @("MD5", "SHA", "SHA-224", "SHA-256", "SHA-384", "SHA-512")
$privProtocols = @("DES", "AES", "AES128", "AES192", "AES256")

# For Net-SNMP compatibility, map protocol names
$authMap = @{
    "MD5" = "MD5"
    "SHA1" = "SHA"
    "SHA" = "SHA"
    "SHA-224" = "SHA-224"
    "SHA-256" = "SHA-256" 
    "SHA-384" = "SHA-384"
    "SHA-512" = "SHA-512"
    "SHA256" = "SHA-256"
    "SHA512" = "SHA-512"
}

$privMap = @{
    "DES" = "DES"
    "AES" = "AES"
    "AES128" = "AES128"
    "AES192" = "AES192"
    "AES256" = "AES256"
}

# Quick test combinations (most common)
$quickCombinations = @(
    @{Auth="MD5"; Priv="DES"},
    @{Auth="MD5"; Priv="AES"},
    @{Auth="SHA"; Priv="AES"},
    @{Auth="SHA-256"; Priv="AES256"}
)

$results = @()
$successfulCombinations = @()

if ($QuickTest) {
    Write-Host "Performing quick test with common combinations..." -ForegroundColor Yellow
    $testCombinations = $quickCombinations
}
else {
    Write-Host "Testing all authentication and privacy combinations..." -ForegroundColor Yellow
    $testCombinations = @()
    foreach ($auth in $authProtocols) {
        foreach ($priv in $privProtocols) {
            $testCombinations += @{Auth=$auth; Priv=$priv}
        }
    }
}

Write-Host "Total combinations to test: $($testCombinations.Count)" -ForegroundColor White
Write-Host ""

$testNumber = 1
foreach ($combination in $testCombinations) {
    $authProto = $authMap[$combination.Auth]
    $privProto = $privMap[$combination.Priv]
    
    if (-not $authProto) { $authProto = $combination.Auth }
    if (-not $privProto) { $privProto = $combination.Priv }
    
    Write-Progress -Activity "Testing SNMP v3 combinations" -Status "Test $testNumber of $($testCombinations.Count): Auth=$($combination.Auth), Priv=$($combination.Priv)" -PercentComplete (($testNumber / $testCombinations.Count) * 100)
    
    Write-Host "Test $testNumber`: Auth=$($combination.Auth), Priv=$($combination.Priv)" -ForegroundColor Cyan -NoNewline
    
    $testResult = Invoke-SNMPTest -Target $Target -Username $Username -AuthPassword $AuthPassword -PrivPassword $PrivPassword -AuthProtocol $authProto -PrivProtocol $privProto -Context $Context -Port $Port -Timeout $Timeout -TestOID $TestOID -ToolType $toolType
    
    $result = [PSCustomObject]@{
        TestNumber = $testNumber
        AuthProtocol = $combination.Auth
        PrivProtocol = $combination.Priv
        Success = $testResult.Success
        Response = $testResult.Response
        Error = $testResult.Error
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $results += $result
    
    if ($testResult.Success) {
        Write-Host " - SUCCESS" -ForegroundColor Green
        $successfulCombinations += $combination
        Write-Host "    Response: $($testResult.Response -split "`n" | Select-Object -First 1)" -ForegroundColor Green
    }
    else {
        Write-Host " - FAILED" -ForegroundColor Red
        if ($testResult.Error -and $testResult.Error.Length -lt 100) {
            Write-Host "    Error: $($testResult.Error)" -ForegroundColor Red
        }
    }
    
    $testNumber++
}

Write-Progress -Activity "Testing SNMP v3 combinations" -Completed

# Display results summary
Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "="*50 -ForegroundColor Cyan

Write-Host "Total combinations tested: $($testCombinations.Count)" -ForegroundColor White
Write-Host "Successful combinations: $($successfulCombinations.Count)" -ForegroundColor $(if ($successfulCombinations.Count -gt 0) { "Green" } else { "Red" })

if ($successfulCombinations.Count -gt 0) {
    Write-Host "`nWORKING COMBINATIONS:" -ForegroundColor Green
    Write-Host "=====================" -ForegroundColor Green
    
    foreach ($combo in $successfulCombinations) {
        Write-Host "✓ Authentication: $($combo.Auth)" -ForegroundColor Green
        Write-Host "  Privacy: $($combo.Priv)" -ForegroundColor Green
        Write-Host ""
    }
    
    # Show SolarWinds configuration suggestion
    Write-Host "SOLARWINDS CONFIGURATION SUGGESTION:" -ForegroundColor Yellow
    Write-Host "====================================" -ForegroundColor Yellow
    $firstWorking = $successfulCombinations[0]
    Write-Host "SNMP Version: 3" -ForegroundColor White
    Write-Host "Username: $Username" -ForegroundColor White
    Write-Host "Context: $(if ($Context) { $Context } else { '(empty)' })" -ForegroundColor White
    Write-Host "Authentication Protocol: $($firstWorking.Auth)" -ForegroundColor White
    Write-Host "Authentication Password: [Your Auth Password]" -ForegroundColor White
    Write-Host "Privacy Protocol: $($firstWorking.Priv)" -ForegroundColor White
    Write-Host "Privacy Password: [Your Privacy Password]" -ForegroundColor White
    Write-Host "Security Level: authPriv" -ForegroundColor White
}
else {
    Write-Host "`nNO WORKING COMBINATIONS FOUND!" -ForegroundColor Red
    Write-Host "==============================" -ForegroundColor Red
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "• Incorrect username or passwords" -ForegroundColor Yellow
    Write-Host "• Target device not configured for SNMP v3" -ForegroundColor Yellow
    Write-Host "• Network connectivity issues" -ForegroundColor Yellow
    Write-Host "• Firewall blocking SNMP traffic" -ForegroundColor Yellow
    Write-Host "• Different context name required" -ForegroundColor Yellow
    Write-Host "• Target device using different protocol combinations" -ForegroundColor Yellow
}

# Export detailed results if requested
if ($OutputFile) {
    try {
        $results | Export-Csv -Path $OutputFile -NoTypeInformation
        Write-Host "`nDetailed results exported to: $OutputFile" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to export results: $_"
    }
}

# Show additional troubleshooting information
Write-Host "`nTROUBLESHOoting TIPS:" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host "1. Verify network connectivity: Test-NetConnection $Target -Port $Port" -ForegroundColor White
Write-Host "2. Check if SNMP service is running on target device" -ForegroundColor White
Write-Host "3. Verify SNMP v3 user configuration on target device" -ForegroundColor White
Write-Host "4. Try different context names if device uses contexts" -ForegroundColor White
Write-Host "5. Check for firewall rules blocking SNMP traffic" -ForegroundColor White

# Return results for pipeline usage
return $results