function New-OrionCustomPropertyWithValues {
    param (
        [string[]]$Hostnames = 'localhost', # Array of server hostnames to run the function against
        [string]$Username, # Username for SWIS connection
        [string]$Password, # Password for SWIS connection
        [string]$PropertyName = 'Test', # Custom property name
        [string]$Description = 'Description', # Description of the custom property
        [string]$ValueType = 'string', # Value type (string, integer, etc.)
        [int]$Size = 4000, # Size for string properties
        [bool]$Mandatory = $false, # Whether the custom property is mandatory
        [string[]]$DefaultValues    # List of predefined values
    )

    # Loop through each hostname provided
    foreach ($Hostname in $Hostnames) {
        try {
            # Connect to the SolarWinds server
            Write-Host "Connecting to SolarWinds server: $Hostname"
            $swis = Connect-Swis -Hostname $Hostname -Username $Username -Password $Password

            # Define parameters for CreateCustomPropertyWithValues
            $params = @(
                $PropertyName, # Custom property name
                $Description, # Description of the custom property
                $ValueType, # Data type (string, integer, etc.)
                $Size, # Size (for string types)
                $null, # ValidRange (not used)
                $null, # Parser (not used)
                $null, # Header (not used)
                $null, # Alignment (not used)
                $null, # Format (not used)
                $null, # Units (not used)
                [string[]]$DefaultValues, # The list of allowed values for this custom property
                $null, # Usages (optional, pass null)
                $Mandatory, # Mandatory or not
                $null             # Default value (optional)
            )

            # Invoke the SWIS verb to create the custom property with values
            Write-Host "Creating custom property '$PropertyName' with predefined values on $Hostname..."
            Invoke-SwisVerb -SwisConnection $swis -EntityName 'Orion.NodesCustomProperties' -Verb 'CreateCustomPropertyWithValues' -Arguments $params
            Write-Host "Successfully created custom property on $Hostname."

        }
        catch {
            Write-Error "Failed to create custom property on $Hostname. Error: $_"
        }
    }
}

# Example usage: Execute this against multiple SolarWinds servers
$servers = @('10.217.161.203', '10.60.15.200', '10.59.15.206', '10.57.15.206', '10.56.15.206', '10.58.15.206', '10.61.131.17')

# Device_Function
<#
$PropertyName = 'Device_Function'
$Description = 'Device function List'
$values = @('Unknown', 'Access', 'Active Directory', 'AMX', 'Backup', 'CCTV', 'Core', 'DataCenter', 'Distro', 'Domain Controller', 'Exchange', 'Firewall', 'iLo', 'IPAM', 'Kubernetes', 'Lighting Controller', 'Load Balancer', 'NMS', 'Oracle', 'Remote Access', 'Router', 'S2S', 'SolarWinds', 'SQL', 'TACACS', 'Telcom', 'WAN', 'Wireless Controller', 'Witness')  
#>

#Device_Type
$PropertyName = 'Device_Category'
$Description = 'What type of device is this?'
$values = @('Appliance','Call Manager','Camera','Container','Control Systems','Database','Firewall','Load Balancer','Palo Alto','Router','Satellite','Server','Switch','Voice Gateway','VoIP Phone','VXRail')

# Department
<#
$PropertyName = 'Department'
$Description = 'What type of device is this?'
$Values = @('MTO', 'SEC', 'Telcom', 'Entertainment')
#>

New-OrionCustomPropertyWithValues -Hostnames $servers -Username 'admin' -Password 'password' -PropertyName $PropertyName -Description $Description -DefaultValues $values
