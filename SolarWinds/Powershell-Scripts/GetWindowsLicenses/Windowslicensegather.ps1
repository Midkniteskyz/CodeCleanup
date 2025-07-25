# gather license information from machine
$licenses = Get-CimInstance -ClassName SoftwareLicensingProduct
 
# filter the licenses
$validLicenses = $licenses | Where-Object { $_.LicenseStatus -eq '1' }
 
# get the current date
$currentdate = get-date

# get the machine name 
$machineName = $env:COMPUTERNAME
 
if ($validLicenses -eq 0) {
    # if no valid license exists
    Write-Host "Message: There are no valid licenses on $machineName"
    Write-Host "Statistic: 1"
    #exit 1
}
else {
    # if a valid license is found
    $license = $validLicenses | Select-Object -First 1
 
    # calculate the expiration date
    $expirationdate = (get-date).addminutes($license.GracePeriodRemaining)

    # days remaining
    $daysleft = ($expirationdate - $currentdate).days
 
    Write-Host "Message: The license '$($license.Name)' is valid. Expiration date: $expirationdate"
    Write-Host "Statistic: $daysleft"
    #exit 0
}