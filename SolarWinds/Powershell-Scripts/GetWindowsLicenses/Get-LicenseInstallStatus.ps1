# Function to check if Windows is activated
function Check-WindowsActivation {
    $windowsStatus = (Get-WmiObject -Class Win32_OperatingSystem).OperatingSystemSKU
    $isActivated = (Get-WmiObject -Class SoftwareLicensingProduct | Where-Object { $_.PartialProductKey -ne $null -and $_.LicenseStatus -eq 1 }).Count -gt 0
    return @{
        "WindowsSKU" = $windowsStatus
        "IsActivated" = $isActivated
    }
}

# Function to check SQL Server license status
function Check-SQLLicense {
    $sqlInstances = Get-Service | Where-Object { $_.Name -like "MSSQL*" }
    $sqlStatus = @()

    foreach ($instance in $sqlInstances) {
        $sqlKeyPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($instance.Name.Replace('MSSQL$', ''))\Setup"
        if (Test-Path $sqlKeyPath) {
            $license = Get-ItemProperty -Path $sqlKeyPath -Name "ProductID" -ErrorAction SilentlyContinue
            $sqlStatus += @{
                "Instance" = $instance.Name
                "LicenseID" = $license.ProductID
                "IsValid" = ($license.ProductID -ne $null)
            }
        }
    }
    return $sqlStatus
}

# Function to check Exchange Server license status
function Check-ExchangeLicense {
    $exchangeStatus = @()
    $exchangePath = "HKLM:\SOFTWARE\Microsoft\Exchange\v15\Setup"
    if (Test-Path $exchangePath) {
        $licenseKey = Get-ItemProperty -Path $exchangePath -Name "ProductKey" -ErrorAction SilentlyContinue
        $exchangeStatus += @{
            "LicenseKey" = $licenseKey.ProductKey
            "IsValid" = ($licenseKey.ProductKey -ne $null)
        }
    }
    return $exchangeStatus
}

# Run checks
$windowsCheck = Check-WindowsActivation
$sqlCheck = Check-SQLLicense
$exchangeCheck = Check-ExchangeLicense

# Output results
Write-Output "Windows Activation Status: $($windowsCheck.IsActivated)"
Write-Output "Windows SKU: $($windowsCheck.WindowsSKU)"
Write-Output "SQL License Status:"
$sqlCheck | Format-Table -AutoSize
Write-Output "Exchange License Status:"
$exchangeCheck | Format-Table -AutoSize
