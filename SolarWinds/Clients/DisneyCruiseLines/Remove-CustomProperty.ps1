function Remove-OrionCustomProperty {
    param (
        [string[]]$Hostnames, # Array of server hostnames to run the function against
        [string]$Username, # Username for SWIS connection
        [string]$Password, # Password for SWIS connection
        [string]$PropertyName              # Custom property name
    )

    # Loop through each hostname provided
    foreach ($Hostname in $Hostnames) {
        try {
            # Connect to the SolarWinds server
            Write-Host "Connecting to SolarWinds server: $Hostname"
            $swis = Connect-Swis -Hostname $Hostname -Username $Username -Password $Password

            # Check if the custom property already exists
            $existingProperty = Get-SwisData $swis "SELECT Field FROM Orion.CustomProperty WHERE Table='NodesCustomProperties' AND Field=@property" @{property = $PropertyName }

            if ($existingProperty) {
                Write-Host "Custom property '$PropertyName' exists on $Hostname. Removing property..."

                # Modify the existing custom property to add the new values
                $params = @(
                    $PropertyName                        # Custom property name
                )

                Invoke-SwisVerb -SwisConnection $swis -EntityName 'Orion.NodesCustomProperties' -Verb 'DeleteCustomProperty' -Arguments $params
                Write-Host "Successfully removed custom property '$PropertyName' on $Hostname."
            }
            else {
                Write-Warning "Custom property '$PropertyName' does not exist on $Hostname."
            }

        }
        catch {
            Write-Error "Failed to update custom property on $Hostname. Error: $_"
        }
    }
}

# Example usage: Add new values to the existing 'Device_Function' custom property
$servers = @('10.217.161.203', '10.60.15.200', '10.59.15.206', '10.57.15.206', '10.56.15.206', '10.58.15.206', '10.61.131.17')
$PropertyName = 'Department'

Remove-OrionCustomProperty -Hostnames $servers -Username 'admin' -Password 'password' -PropertyName $PropertyName