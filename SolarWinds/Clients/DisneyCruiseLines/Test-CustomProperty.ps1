function Test-OrionCustomProperty {
    param (
        [string[]]$Hostnames,              # Array of server hostnames to run the function against
        [string]$Username,                 # Username for SWIS connection
        [string]$Password,                 # Password for SWIS connection
        [string]$PropertyName,             # Custom property name
        [string]$Description,             # Custom property name
        [string]$ValueType,             # Custom property name
        [string]$Size,             # Custom property name
        [string[]]$Values,               # New values to add to the custom property
        [string]$Usage             # Custom property name

    )

    # Loop through each hostname provided
    foreach ($Hostname in $Hostnames) {
        try {
            # Connect to the SolarWinds server
            Write-Host "Connecting to SolarWinds server: $Hostname"
            $swis = Connect-Swis -Hostname $Hostname -Username $Username -Password $Password

            # Check if the custom property already exists
            $existingProperty = Get-SwisData $swis "SELECT PropertyName,Description,ValueType,Size,Value,Usages FROM Orion.CustomProperty WHERE Table='NodesCustomProperties' AND Field=@property" @{property=$PropertyName}

            if ($existingProperty) {
                Write-Host "Custom property '$PropertyName' exists on $Hostname. Validating values..."

                # Retrieve the existing values for the custom property
                [array]$existingValues = Get-SwisData $swis "SELECT Value FROM Orion.CustomPropertyValues WHERE Table='NodesCustomProperties' AND Field=@property" @{property=$PropertyName}

                # Combine existing values with the new values (ensure no duplicates)
                $combinedValues = ($existingValues + $NewValues) | Sort-Object -Unique

                # Modify the existing custom property to add the new values
                $params = @(
                    $PropertyName,                        # Custom property name
                    $existingProperty.Description,        # Keep the same description
                    $existingProperty.MaxLength,          # Keep the same max length (size)
                    [string[]]$combinedValues,            # Updated list of values
                    $null,                                # Usages (optional, pass null)
                    $false,                               # Mandatory (keep as false)
                    $null                                 # Default value (optional)
                )

                Invoke-SwisVerb -SwisConnection $swis -EntityName 'Orion.NodesCustomProperties' -Verb 'ModifyCustomProperty' -Arguments $params
                Write-Host "Successfully updated custom property '$PropertyName' on $Hostname."
            } else {
                Write-Warning "Custom property '$PropertyName' does not exist on $Hostname."
            }

        } catch {
            Write-Error "Failed to update custom property on $Hostname. Error: $_"
        }
    }
}

# Example usage: Add new values to the existing 'Device_Function' custom property
$servers = @('server1.domain.com', 'server2.domain.com')
$Values = @('PropertyName','Description','ValueType','Size','Value','Usages')
$PropertyName = 'Device_Function'

Update-OrionCustomPropertyWithValues -Hostnames $servers -Username 'admin' -Password 'password' -PropertyName $PropertyName -NewValues $newValues
