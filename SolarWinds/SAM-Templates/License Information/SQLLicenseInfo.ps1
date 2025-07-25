# Initialize an array to hold SQL license status information
$sqlStatus = @()

# Get the path for SQL Server instance names in the registry
$sqlInstanceNamesRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names"
$sqlInstanceNames = Get-ChildItem $sqlInstanceNamesRegPath

# Loop through each SQL instance
foreach ($instance in $sqlInstanceNames) {
    # Get the path to the specific instance setup information
    $instancePath = $instance | Get-ItemProperty | Select-Object -ExpandProperty MSSQLServer
    $sqlKeyPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instancePath\Setup"

    # Check if the setup key exists for the SQL instance
    if (Test-Path $sqlKeyPath) {
        # Retrieve licensing and version information
        $license = Get-ItemProperty -Path $sqlKeyPath -Name "ProductID" -ErrorAction SilentlyContinue
        $sqlKeyPathValues = Get-ItemProperty -Path $sqlKeyPath -ErrorAction SilentlyContinue

        # Check if the license ID is valid
        $isValid = ($license.ProductID -ne $null)

        # Store the information in a custom object
        $sqlStatus += [ordered]@{
            "Instance"    = $instance.PSChildName
            "LicenseID"   = $license.ProductID
            "IsValid"      = $isValid
            "Edition"      = $sqlKeyPathValues.Edition
            "Version"      = $sqlKeyPathValues.Version
            "Patch Level"  = $sqlKeyPathValues.PatchLevel
        }
    }
}

# Check if any SQL licenses were found
if ($sqlStatus.Count -eq 0) {
    # If no SQL instances were found
    Write-Host "Message: No SQL Server instances found."
    Write-Host "Statistic: 1"
} else {
    # Loop through each SQL instance status and output the results
    foreach ($status in $sqlStatus) {
        if ($status.IsValid) {
            Write-Host "Message: SQL Server instance '$($status.Instance)' has a valid license."
            Write-Host "Details: License ID: $($status.LicenseID), Edition: $($status.Edition), Version: $($status.Version), Patch Level: $($status.'Patch Level')"
            Write-Host "Statistic: 0"
        } else {
            Write-Host "Message: SQL Server instance '$($status.Instance)' does not have a valid license."
            Write-Host "Statistic: 1"
        }
    }
}


