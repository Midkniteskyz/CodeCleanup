# Define the registry path and value name
$regPath = "HKLM:\Software\Policies\Microsoft\SystemCertificates\AuthRoot"
$valueName = "DisableRootAutoUpdate"

# Check if the registry value exists; if so, remove it
if (Test-Path "$regPath\$valueName") {
    Remove-ItemProperty -Path $regPath -Name $valueName
    Write-Output "Automatic Root Certificates Update has been re-enabled."
} else {
    Write-Output "The setting was not found; no changes made."
}
