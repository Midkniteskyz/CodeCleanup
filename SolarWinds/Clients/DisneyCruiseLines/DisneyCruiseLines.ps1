function Test-Swis {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Enter one or more hostnames for the SolarWinds server(s). If not provided, servers will be read from servers.txt."
        )]
        [string[]]$Hostname,

        [Parameter(Mandatory = $false, HelpMessage = "Username for SWIS connection.")]
        [string]$Username = 'loop1',

        [Parameter(Mandatory = $false, HelpMessage = "Password for SWIS connection.")]
        [string]$Password = '30DayPassword!'
    )

    Begin {
        # Define the root directory for servers.txt
        $scriptRoot = (Get-Item -Path ".\" | Select-Object -ExpandProperty FullName)

        # Load the server list from servers.txt if no Hostname is provided
        if (-not $Hostname) {
            $serverFilePath = Join-Path -Path $scriptRoot -ChildPath "servers.txt"
            
            if (Test-Path $serverFilePath) {
                $Hostname = Get-Content -Path $serverFilePath
            } else {
                Write-Error "No hostnames were provided and servers.txt could not be found."
                return
            }
        }

        # Initialize an array to store successful connections
        $swisConnections = @()
    }

    Process {
        foreach ($server in $Hostname) {
            try {
                # Attempt to connect to SWIS for each server
                Write-Host "Connecting to $server..."
                $swis = Connect-Swis -Hostname $server -Username $Username -Password $Password

                if ($swis) {
                    Write-Host "Successfully connected to $server" -ForegroundColor Green
                    $swisConnections += [pscustomobject]@{
                        Hostname = $server
                        Connection = $swis
                    }
                }
            } catch {
                Write-Error "Failed to connect to $server. Error: $_"
            }
        }
    }

    End {
        # Output the array of successful connections
        if ($swisConnections.Count -gt 0) {
            return $swisConnections
        } else {
            Write-Error "No successful connections were made."
        }
    }
}

function Get-CustomProperty {
    <#
    .SYNOPSIS
        Retrieves custom properties from SolarWinds Orion.

    .DESCRIPTION
        This function connects to specified SolarWinds servers and retrieves custom properties, optionally filtered by custom property names.
        If no hostnames are provided, it reads from a 'servers.txt' file in the script's root directory. You can filter the results using 
        wildcard patterns on the custom property name.

    .PARAMETER Hostname
        An array of hostnames for SolarWinds servers. If not provided, the function reads from 'servers.txt'.

    .PARAMETER Username
        The username for authenticating the connection to the SolarWinds Information Service (SWIS).

    .PARAMETER Password
        The password associated with the provided username for connecting to SWIS.

    .PARAMETER PropertyName
        An array of custom property names to filter by. You can use wildcards (e.g., 'Test*'). If omitted, all custom properties are returned.

    .EXAMPLE
        C:\PS> Get-CustomProperty -Hostname "solarwinds-server1" -Username "admin" -Password "password"
        Retrieves all custom properties from "solarwinds-server1".

    .EXAMPLE
        C:\PS> Get-CustomProperty -PropertyName "Location"
        Retrieves the "Location" custom property from the servers listed in 'servers.txt'.

    .NOTES
        Name: Get-CustomProperty
        Author: Ryan Woolsey
        Last Edit: <Last Edit Date>
        Version: 1.0
        Keywords: SolarWinds, Custom Property, OrionSDK, PowerShell
    .LINK
        https://github.com/solarwinds/OrionSDK/wiki/PowerShell
    .INPUTS
        None. The function accepts input from parameters.
    .OUTPUTS
        System.Object. Custom property details.
    #Requires -Version 2.0
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Enter one or more hostnames for the SolarWinds server(s). If not provided, servers will be read from servers.txt."
        )]
        [string[]]$Hostname,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "Enter the username for the SWIS connection."
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "Enter the password for the SWIS connection."
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Password,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Enter one or more custom property names to filter by. Supports wildcards."
        )]
        [string[]]$PropertyName
    )

    Begin {
        Write-Verbose -Message "Entering the BEGIN block."
        
        # Define the root directory using $PSScriptRoot for consistency
        $scriptRoot = $PSScriptRoot

        # Load the server list from servers.txt if no Hostname is provided
        if (-not $Hostname) {
            $serverFilePath = Join-Path -Path $scriptRoot -ChildPath "servers.txt"
            
            if (Test-Path $serverFilePath) {
                $Hostname = Get-Content -Path $serverFilePath
                Write-Verbose -Message "Hostnames loaded from servers.txt."
            } else {
                Write-Error "No hostnames were provided and servers.txt could not be found."
                return
            }
        }

        # Initialize the results table
        $results = @()

        # Build the dynamic WHERE clause if PropertyName is provided
        $whereClause = ""
        if ($PropertyName) {
            if ($PropertyName -like '*`*') {
                # Handle case where PropertyName contains a wildcard
                $whereClause = ("`nWHERE " + ($PropertyName.Replace('*', '%') | ForEach-Object { "CP.Field LIKE '$_'" })).TrimEnd(' OR')
                Write-Verbose -Message "Wildcard detected. WHERE clause: $whereClause"
            } else {
                # Handle exact matches
                $whereClause = ("`nWHERE " + ($PropertyName | ForEach-Object { "CP.Field = '$_'" })).TrimEnd(' OR')
                Write-Verbose -Message "No wildcard detected. WHERE clause: $whereClause"
            }
        }

        # Define the base SWQL query
        $baseQuery = @"
SELECT 
    CP.Table, 
    CP.Field, 
    CP.DataType, 
    CP.MaxLength, 
    CP.StorageMethod, 
    CP.Description, 
    CP.TargetEntity, 
    CP.Mandatory, 
    CP.Default, 
    CP.DisplayName AS CPDisplayName,
    CPU.IsForAlerting, 
    CPU.IsForFiltering, 
    CPU.IsForGrouping, 
    CPU.IsForReporting, 
    CPU.IsForEntityDetail, 
    CPU.IsForAssetInventory,
    CPV.Value, 
    CPV.DisplayName AS CPVDisplayName, 
    CPV.Description AS CPVDescription
FROM 
    Orion.CustomProperty AS CP
LEFT JOIN 
    Orion.CustomPropertyUsage AS CPU
    ON CP.Table = CPU.Table 
    AND CP.Field = CPU.Field
LEFT JOIN 
    Orion.CustomPropertyValues AS CPV
    ON CP.Table = CPV.Table 
    AND CP.Field = CPV.Field
"@ + $whereClause

        Write-Verbose -Message "SWQL query built: $baseQuery"
    }

    Process {
        foreach ($server in $Hostname) {
            Write-Host "Connecting to $server..."

            # Attempt to connect to SWIS
            try {
                $swis = Connect-Swis -Hostname $server -Username $Username -Password $Password

                if ($swis) {
                    Write-Host "Successfully connected to $server" -ForegroundColor Green
                    Write-Verbose "Connection to $server established."
                }
            } catch {
                Write-Error "Failed to connect to $server. Error: $_"
                continue # Skip to the next host if connection fails
            }

            # Attempt to run the SWQL query
            try {
                $queryParams = @{
                    SwisConnection = $swis
                    Query = $baseQuery
                }
                $data = Get-SwisData @queryParams
                Write-Verbose "SWQL query executed successfully on $server."
            } catch {
                Write-Error "Failed to execute SWQL query on $server. Error: $_"
                continue # Skip to the next host if query fails
            }

            # Parse the data into results
            foreach ($row in $data) {
                $result = [ordered]@{ Hostname = $server }

                # Dynamically add all properties from the row data
                foreach ($property in $row.PSObject.Properties) {
                    $result[$property.Name] = $property.Value
                }

                # Add to the results table
                $results += [pscustomobject]$result
            }
        }
    }

    End {
        if ($results) {
            # Output the results
            Write-Host "Query finished."
            return $results | Select-Object HostName, Table, Field, Description, DataType, MaxLength, Mandatory, Value, Default, IsForAlerting, IsForFiltering, IsForGrouping, IsForReporting, IsForEntityDetail, IsAssetInventory | Out-GridView
        } else {
            Write-Host "No results found for the custom property $PropertyName."
        }
    }
}

function New-CustomProperty {
    <#
    .SYNOPSIS
        Creates a new custom property on multiple SolarWinds Orion servers.

    .DESCRIPTION
        This function creates a new custom property on specified SolarWinds servers, allowing for customization of the property name, description, data type, and other properties. 
        The script supports multiple SolarWinds instances, reading from 'servers.txt' if no hostnames are provided.

    .PARAMETER Hostname
        An array of hostnames for SolarWinds servers. If not provided, the function reads from 'servers.txt'.

    .PARAMETER Username
        The username for authenticating the connection to the SolarWinds Information Service (SWIS).

    .PARAMETER Password
        The password associated with the provided username for connecting to SWIS.

    .PARAMETER PropertyName
        The name of the custom property you want to create.

    .PARAMETER Description
        A description for the custom property. This is optional.

    .PARAMETER ValueType
        The data type for the custom property. Must be one of: string, integer, datetime, single, double, boolean.

    .PARAMETER Size
        For string types, this is the maximum length of the values, in characters. The default is 250.

    .PARAMETER Mandatory
        Specifies whether the custom property should be mandatory in the Add Node wizard in the Orion web console.

    .PARAMETER DefaultValue
        Specifies the default value for the custom property. This is optional.

    .EXAMPLE
        C:\PS> New-CustomProperty -Hostname "solarwinds-server1" -Username "admin" -Password "password" -PropertyName "Location" -ValueType "string"
        
        Creates a new custom property "Location" on the SolarWinds server "solarwinds-server1".

    .NOTES
        Name: New-CustomProperty
        Author: Ryan Woolsey
        Last Edit: <Last Edit Date>
        Version: 1.0
        Keywords: SolarWinds, Custom Property, OrionSDK, PowerShell

    .LINK
        https://github.com/solarwinds/OrionSDK/wiki/PowerShell
    .INPUTS
        None.
    .OUTPUTS
        None.
    #Requires -Version 2.0
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Enter one or more hostnames for the SolarWinds server(s). If not provided, servers will be read from servers.txt."
        )]
        [string[]]$Hostname,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the username for the SWIS connection.")]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the password for the SWIS connection.")]
        [ValidateNotNullOrEmpty()]
        [string]$Password,

        [Parameter(Mandatory = $true, HelpMessage = "Enter a name for the custom property.")]
        [ValidateNotNullOrEmpty()]
        [string]$PropertyName,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a description for the custom property.")]
        [string]$Description,

        [Parameter(Mandatory = $true, HelpMessage = "The data type for the custom property. The following types are allowed: string, integer, datetime, single, double, boolean.")]
        [ValidateSet('string', 'integer', 'datetime', 'single', 'double', 'boolean')]
        [string]$ValueType,

        [Parameter(Mandatory = $false, HelpMessage = "For string types, this is the maximum length of the values, in characters. Ignored for other types. The default is 250.")]
        [int]$Size = 250,

        [Parameter(Mandatory = $false, HelpMessage = "Defaults to false. If set to true, the Add Node wizard in the Orion web console will require that a value for this custom property be specified at node creation time.")]
        [bool]$Mandatory = $false,

        [Parameter(Mandatory = $false, HelpMessage = "You can pass null for this. If you provide a value, this will be the default value for new nodes.")]
        [string]$DefaultValue
    )

    Begin {
        Write-Verbose -Message "Entering the BEGIN block."

        # Define the root directory using $PSScriptRoot
        $scriptRoot = $PSScriptRoot

        # Load the server list from servers.txt if no Hostname is provided
        if (-not $Hostname) {
            $serverFilePath = Join-Path -Path $scriptRoot -ChildPath "servers.txt"
            
            if (Test-Path $serverFilePath) {
                $Hostname = Get-Content -Path $serverFilePath
                Write-Verbose -Message "Hostnames loaded from servers.txt."
            } else {
                Write-Error "No hostnames were provided and servers.txt could not be found."
                return
            }
        }

        # Initialize results table
        $createdProperties = @()
    
        # Define the parameters for the custom property
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
            @{
                IsForAlerting = $true
                IsForFiltering = $true
                IsForGrouping = $true
                IsForReporting = $true
                IsForEntityDetail = $true
                IsForAssetInventory = $true
            } # Usages
            $Mandatory,
            $DefaultValue
        )
    }

    Process {
        foreach ($server in $Hostname) {
            Write-Host "Connecting to $server..."

            # Attempt to connect to SWIS
            try {
                $swis = Connect-Swis -Hostname $server -Username $Username -Password $Password

                if ($swis) {
                    Write-Host "Successfully connected to $server" -ForegroundColor Green
                    Write-Verbose -Message "Connection to $server established."
                }

            } catch {
                Write-Error "Failed to connect to $server. Error: $_"
                continue # Skip to the next host if connection fails
            }

            # Attempt to create the custom property
            try {
                Invoke-SwisVerb -SwisConnection $swis -EntityName 'Orion.NodesCustomProperties' -Verb 'CreateCustomProperty' -Arguments $params -ErrorAction Stop
                Write-Host "Custom property '$PropertyName' created successfully on $server." -ForegroundColor Green

                # Add to the results
                $createdProperties += [pscustomobject]@{
                    Server = $server
                    PropertyName = $PropertyName
                    Description = $Description
                    ValueType = $ValueType
                }

            } catch {
                Write-Error "Failed to create custom property '$PropertyName' on $server. Error: $_"
                continue # Skip to the next host if query fails
            }
        }
    }

    End {
        Write-Verbose -Message "Entering the END block."

        if ($createdProperties.Count -gt 0) {
            Write-Host "`nCustom Properties Created:" -ForegroundColor Cyan
            $createdProperties | Format-Table -AutoSize
        } else {
            Write-Host "No custom properties were created."
        }
    }
}

function Add-CustomPropertyValues {
    <#
    .SYNOPSIS
        Adds new values to an existing custom property on multiple SolarWinds Orion servers.

    .DESCRIPTION
        This function connects to specified SolarWinds servers and updates the custom property with new values. 
        It ensures that the custom property already exists before adding values, and combines the existing values with the new ones without duplicates.

    .PARAMETER Hostname
        An array of hostnames for SolarWinds servers. If not provided, the function reads from 'servers.txt'.

    .PARAMETER Username
        The username for authenticating the connection to the SolarWinds Information Service (SWIS).

    .PARAMETER Password
        The password associated with the provided username for connecting to SWIS.

    .PARAMETER PropertyName
        The name of the custom property you want to update with new values.

    .PARAMETER NewValues
        An array of new values to add to the custom property.

    .EXAMPLE
        C:\PS> Add-CustomPropertyValues -Hostname "solarwinds-server1" -Username "admin" -Password "password" -PropertyName "Department" -NewValues "Finance", "Operations"
        
        This will add "Finance" and "Operations" to the "Department" custom property on "solarwinds-server1".

    .NOTES
        Name: Add-CustomPropertyValues
        Author: Ryan Woolsey
        Last Edit: <Last Edit Date>
        Version: 1.0
        Keywords: SolarWinds, Custom Property, OrionSDK, PowerShell

    .LINK
        https://github.com/solarwinds/OrionSDK/wiki/PowerShell
    .INPUTS
        None. The function accepts input from parameters.
    .OUTPUTS
        System.Object. Custom property update details.
    #Requires -Version 2.0
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Enter one or more hostnames for the SolarWinds server(s). If not provided, servers will be read from servers.txt."
        )]
        [string[]]$Hostname,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the username for the SWIS connection.")]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the password for the SWIS connection.")]
        [ValidateNotNullOrEmpty()]
        [string]$Password,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the custom property name to update.")]
        [ValidateNotNullOrEmpty()]
        [string]$PropertyName,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the new values to add to the custom property.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$NewValues
    )

    Begin {
        Write-Verbose -Message "Entering the BEGIN block."

        # Define the root directory using $PSScriptRoot
        $scriptRoot = $PSScriptRoot

        # Load the server list from servers.txt if no Hostname is provided
        if (-not $Hostname) {
            $serverFilePath = Join-Path -Path $scriptRoot -ChildPath "servers.txt"
            
            if (Test-Path $serverFilePath) {
                $Hostname = Get-Content -Path $serverFilePath
                Write-Verbose -Message "Hostnames loaded from servers.txt."
            } else {
                Write-Error "No hostnames were provided and servers.txt could not be found."
                return
            }
        }

        # Initialize the results table
        $updatedProperties = @()

        # Define the base SWQL query to fetch existing custom property values
        $baseQuery = @"
SELECT 
    CP.Table, 
    CP.Field, 
    CP.MaxLength, 
    CP.Description, 
    CPV.Value
FROM 
    Orion.CustomProperty AS CP
LEFT JOIN 
    Orion.CustomPropertyValues AS CPV
    ON CP.Table = CPV.Table 
    AND CP.Field = CPV.Field
WHERE CP.Field = '$PropertyName'
"@
    }

    Process {
        foreach ($server in $Hostname) {
            Write-Host "Connecting to $server..."

            # Attempt to connect to SWIS
            try {
                $swis = Connect-Swis -Hostname $server -Username $Username -Password $Password

                if ($swis) {
                    Write-Host "Successfully connected to $server" -ForegroundColor Green
                    Write-Verbose -Message "Connection to $server established."
                }
            } catch {
                Write-Error "Failed to connect to $server. Error: $_"
                continue # Skip to the next host if connection fails
            }

            # Attempt to run the SWQL query
            try {
                # Check if the custom property exists
                $queryParams = @{
                    SwisConnection = $swis
                    Query          = $baseQuery
                }
                $existingProperty = Get-SwisData @queryParams

                if ($existingProperty) {
                    Write-Host "Custom property '$PropertyName' exists on $server. Updating values..."
                    Write-Verbose -Message "Custom property '$PropertyName' found on $server."

                    # Retrieve the existing values for the custom property
                    [array]$existingValues = $existingProperty.Value

                    # Combine existing values with the new values (ensure no duplicates)
                    $combinedValues = ($existingValues + $NewValues) | Sort-Object -Unique

                    # Modify the existing custom property to add the new values
                    $params = @(
                        $PropertyName, # Custom property name
                        $existingProperty[0].Description, # Keep the same description
                        $existingProperty[0].MaxLength, # Keep the same max length (size)
                        [string[]]$combinedValues           # Updated list of values
                    )

                    # Update the custom property values
                    try {
                        Invoke-SwisVerb -SwisConnection $swis -EntityName 'Orion.NodesCustomProperties' -Verb 'ModifyCustomProperty' -Arguments $params -ErrorAction Stop
                        Write-Host "Successfully updated custom property '$PropertyName' on $server." -ForegroundColor Green

                        # Add to the results
                        $updatedProperties += [pscustomobject]@{
                            Server = $server
                            PropertyName = $PropertyName
                            UpdatedValues = $combinedValues -join ", "
                        }

                    } catch {
                        Write-Error "Failed to update custom property '$PropertyName' on $server. Error: $_"
                        continue # Skip to the next host if query fails
                    }

                } else {
                    Write-Error "Failed to update '$PropertyName' on $server. The property does not exist."
                    continue
                }

            } catch {
                Write-Error "Failed to execute SWQL query on $server. Error: $_"
                continue # Skip to the next host if query fails
            }
        }
    }

    End {
        Write-Verbose -Message "Entering the END block."

        if ($updatedProperties.Count -gt 0) {
            Write-Host "`nUpdated Custom Properties:" -ForegroundColor Cyan
            $updatedProperties | Format-Table -AutoSize
        } else {
            Write-Host "No custom properties were updated."
        }
    }
}

function Remove-CustomProperty {
    <#
    .SYNOPSIS
        Removes custom properties from multiple SolarWinds Orion servers.

    .DESCRIPTION
        This function connects to specified SolarWinds servers and removes custom properties based on a provided name or wildcard (e.g., 'Test*'). 
        It prompts the user for confirmation before executing the removal.

    .PARAMETER Hostname
        An array of hostnames for SolarWinds servers. If not provided, the function reads from 'servers.txt'.

    .PARAMETER Username
        The username for authenticating the connection to the SolarWinds Information Service (SWIS).

    .PARAMETER Password
        The password associated with the provided username for connecting to SWIS.

    .PARAMETER PropertyName
        The name of the custom property to remove. Supports wildcards (e.g., 'Test*').

    .EXAMPLE
        C:\PS> Remove-CustomProperty -Hostname "solarwinds-server1" -Username "admin" -Password "password" -PropertyName "Test*"
        
        This removes all custom properties starting with "Test" on "solarwinds-server1".

    .NOTES
        Name: Remove-CustomProperty
        Author: Ryan Woolsey
        Last Edit: <Last Edit Date>
        Version: 1.0
        Keywords: SolarWinds, Custom Property, OrionSDK, PowerShell

    .LINK
        https://github.com/solarwinds/OrionSDK/wiki/PowerShell
    .INPUTS
        None. The function accepts input from parameters.
    .OUTPUTS
        System.Object. Custom property removal details.
    #Requires -Version 2.0
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Enter one or more hostnames for the SolarWinds server(s). If not provided, servers will be read from servers.txt."
        )]
        [string[]]$Hostname,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "Enter the username for the SWIS connection."
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "Enter the password for the SWIS connection."
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Password,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "Enter the name of the custom property to remove. Supports wildcards."
        )]
        [ValidateNotNullOrEmpty()]
        [string]$PropertyName
    )

    Begin {
        Write-Verbose -Message "Entering the BEGIN block."

        # Define the root directory using $PSScriptRoot
        $scriptRoot = $PSScriptRoot

        # Load the server list from servers.txt if no Hostname is provided
        if (-not $Hostname) {
            $serverFilePath = Join-Path -Path $scriptRoot -ChildPath "servers.txt"
            
            if (Test-Path $serverFilePath) {
                $Hostname = Get-Content -Path $serverFilePath
                Write-Verbose -Message "Hostnames loaded from servers.txt."
            } else {
                Write-Error "No hostnames were provided and servers.txt could not be found."
                return
            }
        }

        # Initialize results table
        $removalResults = @()

        # Replace * with %
        $PropertyName = $PropertyName.Replace('*','%')

        # Define the base SWQL query to fetch custom properties based on the wildcard
        $baseQuery = @"
SELECT Field, DisplayName 
FROM Orion.CustomProperty
WHERE Field LIKE '$PropertyName'
"@
    }

    Process {
        foreach ($server in $Hostname) {
            Write-Host "Connecting to $server..."

            # Attempt to connect to SWIS
            try {
                $swis = Connect-Swis -Hostname $server -Username $Username -Password $Password

                if ($swis) {
                    Write-Host "Successfully connected to $server" -ForegroundColor Green
                    Write-Verbose -Message "Connection to $server established."
                }
            } catch {
                Write-Error "Failed to connect to $server. Error: $_"
                continue # Skip to the next host if connection fails
            }

            # Retrieve custom properties matching the wildcard
            try {
                $queryParams = @{
                    SwisConnection = $swis
                    Query = $baseQuery
                }
                $propertiesToRemove = Get-SwisData @queryParams

                if ($propertiesToRemove.Count -eq 0) {
                    Write-Host "No matching custom properties found on $server for pattern '$PropertyName'."
                    continue
                }

                # Display the matching custom properties and ask for confirmation
                Write-Host "`nThe following custom properties will be removed from $server :"
                $propertiesToRemove | Format-Table -AutoSize

                $confirmation = Read-Host "Are you sure you want to remove these custom properties? (y/n)"
                if ($confirmation -ne 'y') {
                    Write-Host "Skipping removal on $server."
                    continue
                }

                # Remove each custom property
                foreach ($property in $propertiesToRemove) {
                    try {
                        Invoke-SwisVerb -SwisConnection $swis -EntityName 'Orion.NodesCustomProperties' -Verb 'DeleteCustomProperty' -Arguments $property.Field
                        Write-Host "Successfully removed custom property '$($property.Field)' on $server." -ForegroundColor Green

                        # Add to the results table
                        $removalResults += [pscustomobject]@{
                            Server = $server
                            PropertyName = $property.Field
                        }

                    } catch {
                        Write-Error "Failed to remove custom property '$($property.Field)' on $server. Error: $_"
                        continue # Skip to the next property if removal fails
                    }
                }

            } catch {
                Write-Error "Failed to retrieve custom properties on $server. Error: $_"
                continue # Skip to the next host if query fails
            }
        }
    }

    End {
        Write-Verbose -Message "Entering the END block."

        if ($removalResults.Count -gt 0) {
            Write-Host "`nRemoved Custom Properties:" -ForegroundColor Cyan
            $removalResults | Format-Table -AutoSize
        } else {
            Write-Host "No custom properties were removed."
        }
    }
}

function Set-CustomProperty {
        
    <#
    .SYNOPSIS
        Updates an existing custom property for nodes in SolarWinds Orion.

    .DESCRIPTION
        This function connects to specified SolarWinds servers, checks if a custom property with the specified name exists, and then updates the values for that custom property. 
        If no hostnames are provided, the function will attempt to read a list of servers from a servers.txt file located in the script's root directory.

    .PARAMETER Hostname
        An array of one or more hostnames for SolarWinds servers. If this parameter is not provided, the function will attempt to read the hostnames from a 'servers.txt' file located in the script's root directory.

    .PARAMETER Username
        The username for authenticating the connection to the SolarWinds Information Service (SWIS).

    .PARAMETER Password
        The password associated with the provided username for connecting to the SolarWinds Information Service (SWIS).

    .PARAMETER PropertyName
        The name of the custom property you want to update.

    .PARAMETER Values
        An array of values to be assigned to the specified custom property.

    .EXAMPLE
        C:\PS> Set-CustomProperty -Hostname "solarwinds-server1" -Username "admin" -Password "password" -PropertyName "Location" -Values "HQ", "Remote"
        
        This command connects to the SolarWinds server at "solarwinds-server1" and updates the custom property named "Location" with the values "HQ" and "Remote".

    .EXAMPLE
        C:\PS> Set-CustomProperty -PropertyName "Department" -Values "IT", "HR", "Finance"

        This command reads the hostnames from 'servers.txt', connects to the SolarWinds servers, and updates the "Department" custom property with the values "IT", "HR", and "Finance".

    .NOTES
        Name: Set-CustomProperty
        Author: Ryan Woolsey
        Last Edit: 9-17-2024
        Version: 1.0
        Keywords: SolarWinds, Custom Property, OrionSDK, PowerShell
        Link: https://github.com/solarwinds/OrionSDK/wiki/PowerShell
        The script reads from 'servers.txt' if the Hostname parameter is not provided.

    .LINK
        https://github.com/solarwinds/OrionSDK/wiki/PowerShell

    .INPUTS
        None. The function accepts input from parameters.

    .OUTPUTS
        None. The function does not return an output object.

    #Requires -Version 2.0
    #>


    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Enter one or more hostnames for the SolarWinds server(s). If not provided, servers will be read from servers.txt."
        )]
        [string[]]$Hostname,

        [Parameter(
            Mandatory = $true, 
            HelpMessage = "Enter the username for the SWIS connection."
        )]
        [string]$Username,

        [Parameter(
            Mandatory = $true, 
            HelpMessage = "Enter the password for the SWIS connection."
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Password,

        [Parameter(
            Mandatory = $true, 
            HelpMessage = "Enter the name of the custom property to update."
        )]
        [ValidateNotNullOrEmpty()]
        [string]$PropertyName,

        [Parameter(
            Mandatory = $true, 
            HelpMessage = "Enter the values for the custom property."
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$Values
    )

    Begin {
        Write-Verbose -Message "Entering the BEGIN block [$($MyInvocation.MyCommand.CommandType): $($MyInvocation.MyCommand.Name)]."
        
        # Define the root directory for servers.txt
        $scriptRoot = $PSScriptRoot 

        # Load the server list from servers.txt if no Hostname is provided
        if (-not $Hostname) {
            $serverFilePath = Join-Path -Path $scriptRoot -ChildPath "servers.txt"
            
            if (Test-Path $serverFilePath) {
                $Hostname = Get-Content -Path $serverFilePath
            }
            else {
                Write-Error "No hostnames were provided and servers.txt could not be found."
                return
            }
        } 

        # Define the base SWQL query
        $baseQuery = @"
SELECT Table, Field, DataType, MaxLength, Description, TargetEntity, Mandatory, Default 
FROM Orion.CustomProperty 
WHERE Field = '$PropertyName' 
"@

    }

    Process {
        Write-Verbose -Message "Entering the PROCESS block [$($MyInvocation.MyCommand.CommandType): $($MyInvocation.MyCommand.Name)]."

        foreach ($server in $Hostname) {
            Write-Host "Connecting to $server..."

            # Attempt to connect to SWIS
            try {
                # Attempt to connect to SWIS for each server
                $swis = Connect-Swis -Hostname $server -Username $Username -Password $Password

                if ($swis) {
                    Write-Host "Successfully connected to $server" -ForegroundColor Green
                }

            }
            catch {
                Write-Error "Failed to connect to $server. Error: $_"
                continue # Skip to the next host if connection fails
            }

            # Check if the custom property exists
            try {
                $queryParams = @{
                    SwisConnection = $swis
                    Query          = $baseQuery
                }
                $data = Get-SwisData @queryParams

                if ($data) {
                    Write-Host "$PropertyName exists on $server." -ForegroundColor Green
                    
                    # Keep the existing custom property properties
                    $params = @(
                        $data.Field, # Custom property name
                        $data.Description, # Keep the same description
                        $data.MaxLength, # Keep the same max length (size)
                        $Values # Updated list of values
                    )

                    # Output verbose details
                    Write-Verbose "Custom Property Name: $($data.Field)"
                    Write-Verbose "Description: $($data.Description)"
                    Write-Verbose "Max Length: $($data.MaxLength)"
                    Write-Verbose "Values: $($Values -join ', ')"

                    try {
                        Write-Host "Replacing existing values on $PropertyName with $Values."
                        Invoke-SwisVerb -SwisConnection $swis -EntityName 'Orion.NodesCustomProperties' -Verb 'ModifyCustomProperty' -Arguments $params
                    }
                    catch {
                        Write-Error "Failed to update $PropertyName on $server. Error: $_"
                        continue # Skip to the next host if query fails
                    }
                }
            }
            catch {
                Write-Error "Failed to execute SWQL query on $server. Error: $_"
                continue # Skip to the next host if query fails
            }
        }

    }

    End {
        Write-Verbose -Message "Entering the END block [$($MyInvocation.MyCommand.CommandType): $($MyInvocation.MyCommand.Name)]."

        # Output the results

    }
}


# Example usage: Execute this against multiple SolarWinds servers
$servers = @(
    'localhost',
    '10.217.161.203', # LightHouse
    '10.60.15.200', # Wish
    '10.59.15.206', # Wonder
    '10.57.15.206', # Fantasy
    '10.56.15.206', # Dream
    '10.58.15.206' # Magic
    '10.61.131.17' # Castaway
    )

$Username = 'loop1'
$Password = '30DayPassword!'

# Get-CustomProperty -Hostname $servers -Username $Username -Password $Password -PropertyName "Environment" -Verbose

# New-CustomProperty -Hostname $servers -Username $Username -Password $password -PropertyName "Environment" -ValueType "string" -Verbose

# Add-CustomPropertyValues -Hostname $servers -Username $username -Password $password -PropertyName 'Environment' -NewValues 'Lighthouse Point', 'Castaway', 'Dream' -Verbose

# Remove-CustomProperty -Hostname $servers -Username $Username -Password $Password -PropertyName "Test*" -Verbose

# Set-CustomProperty -Hostname $servers -Username $Username -Password $Password -PropertyName "Environment" -Values 'Lighthouse Point', 'Castaway', 'Dream', 'Fantasy' -Verbose
