function Compare-IisSites {
    param (
        [string]$SiteName1,
        [string]$SiteName2
    )

    # Import the WebAdministration module if not already imported
    Import-Module WebAdministration

    $site1Config = Get-WebConfiguration "/system.applicationHost/sites/site[@name='$SiteName1']" -PSPath "IIS:\"
    $site2Config = Get-WebConfiguration "/system.applicationHost/sites/site[@name='$SiteName2']" -PSPath "IIS:\"

    if ($site1Config -eq $null -or $site2Config -eq $null) {
        Write-Host "One or both sites not found."
        return
    }

    $comparisonResult = Compare-Object -ReferenceObject $site1Config.Attributes -DifferenceObject $site2Config.Attributes -Property "name", "value"

    if ($comparisonResult.Count -eq 0) {
        Write-Host "Configurations are identical."
    } else {
        Write-Host "Differences found:"
        $comparisonResult | ForEach-Object {
            Write-Host "Name: $($_.InputObject.name), Site1: $($_.InputObject.value), Site2: $($_.InputObject2.value)"
        }
    }
}

# Example usage
Compare-IisSites -SiteName1 "Site1" -SiteName2 "Site2"
