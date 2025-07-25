function OrionCustomProperty {
    param (
        [string]$Hostname,
        [string]$Username,
        [string]$Password,
        [string]$PropertyName,           # The name of the custom property
        [string]$Description,            # A description of the property to be shown in the UI
        [string]$ValueType,              # Data type: string, integer, datetime, single, double, boolean
        [int]$Size = 0,                  # For string types, the max length in characters
        [bool]$Mandatory = $false,       # If true, the custom property is required when adding new nodes
        [string]$DefaultValue = $null    # Optional default value for new nodes
    )

    # Validating ValueType
    $allowedTypes = @('string', 'integer', 'datetime', 'single', 'double', 'boolean')
    if ($ValueType -notin $allowedTypes) {
        throw "Invalid ValueType. Allowed values are: $($allowedTypes -join ', ')"
    }

    # Connect to SWIS
    $swis = Connect-Swis -Hostname $Hostname -Username $Username -Password $Password

    # Define parameters for the custom property
    $params = @(
        $PropertyName,
        $Description,
        $ValueType,
        $Size,
        $null,        # ValidRange - unused, pass null
        $null,        # Parser - unused, pass null
        $null,        # Header - unused, pass null
        $null,        # Alignment - unused, pass null
        $null,        # Format - unused, pass null
        $null,        # Units - unused, pass null
        $null,        # Usages - optional, pass null
        $Mandatory,
        $DefaultValue
    )

    # Invoke the SWIS verb to create the custom property
    try {
        Invoke-SwisVerb -SwisConnection $swis -EntityName 'Orion.NodesCustomProperties' -Verb 'CreateCustomProperty' -Arguments $params
        Write-Output "Custom property '$PropertyName' created successfully."
    } catch {
        Write-Error "Failed to create custom property. Error: $_"
    }
}

# Example usage:
# New-OrionCustomProperty -Hostname 'localhost' -Username 'admin' -Password '' -PropertyName 'Test1' -Description 'This is my description' -ValueType 'string' -Size 50 -Mandatory $true -DefaultValue 'N/A'
