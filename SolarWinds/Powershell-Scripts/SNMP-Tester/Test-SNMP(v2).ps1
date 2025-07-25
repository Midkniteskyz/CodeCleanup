param (
    [Parameter(Mandatory)]
    [string]$Target,

    [Parameter(Mandatory)]
    [string]$Username,

    [Parameter()]
    [string]$Context = "",

    [Parameter(Mandatory)]
    [string]$AuthPassword,

    [Parameter(Mandatory)]
    [string]$PrivPassword
)

# Define protocol options
$authProtocols = @("MD5", "SHA", "SHA-256", "SHA-512")
$privProtocols = @("DES", "AES", "AES-192", "AES-256")

# Set OID to test - sysDescr.0
$oid = "1"

# Path to snmpget.exe (edit if needed)
$snmpget = "snmpget.exe"

# Track working combinations
$workingCombos = @()

Write-Host "Testing SNMPv3 combinations on $Target with user '$Username'..."

foreach ($auth in $authProtocols) {
    foreach ($priv in $privProtocols) {
        $args = @(
            "-v3"
            "-l", "authPriv"
            "-u", $Username
            "-a", $auth
            "-A", $AuthPassword
            "-x", $priv
            "-X", $PrivPassword
        )

        if ($Context -ne "") {
            $args += @("-n", $Context)
        }

        $args += @($Target, $oid)

        try {
            $result = & $snmpget @args 2>&1
            if ($LASTEXITCODE -eq 0 -and $result -match "SNMPv2") {
                Write-Host "✅ SUCCESS: Auth=$auth, Priv=$priv"
                $workingCombos += [PSCustomObject]@{
                    Auth = $auth
                    Priv = $priv
                    Response = $result
                }
            }
            else {
                Write-Host "❌ FAIL: Auth=$auth, Priv=$priv"
            }
        }
        catch {
            Write-Host "⚠️ ERROR running SNMP test: $_"
        }
    }
}

Write-Host "`n=== SUMMARY ==="
if ($workingCombos.Count -gt 0) {
    $workingCombos | Format-Table -AutoSize
} else {
    Write-Host "No valid SNMPv3 auth/privacy combinations found."
}
