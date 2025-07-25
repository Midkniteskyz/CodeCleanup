function Add-CustomPropertyValues {
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
        [string]$Username,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the password for the SWIS connection.")]
        [string]$Password,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the custom property name to update.")]
        [string]$PropertyName,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the new values to add to the custom property.")]
        [string[]]$NewValues
    )

    Begin {

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

        # Define the base SWQL query
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
    Orion.CustomPropertyUsage AS CPU
    ON CP.Table = CPU.Table 
    AND CP.Field = CPU.Field
LEFT JOIN 
    Orion.CustomPropertyValues AS CPV
    ON CP.Table = CPV.Table 
    AND CP.Field = CPV.Field
Where CP.Field = '$PropertyName'
"@
    }

    Process {
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

            # Attempt to run the SWQL query
            try {
                # Check if the custom property already exists
                $queryParams = @{
                    SwisConnection = $swis
                    Query          = $baseQuery
                }
                $existingProperty = Get-SwisData @queryParams

                if ($existingProperty) {
                    Write-Host "Custom property '$PropertyName' exists on $server. Updating values..."

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

                    # Write-Host each element in the params array with meaningful labels
                    # Write-Host "Custom Property Name: $($params[0])"
                    # Write-Host "Description: $($params[1])"
                    # Write-Host "Max Length: $($params[2])"
                    # Write-Host "Combined Values: $($params[3] -join ', ')"

                    Invoke-SwisVerb -SwisConnection $swis -EntityName 'Orion.NodesCustomProperties' -Verb 'ModifyCustomProperty' -Arguments $params -ErrorAction Stop
                    Write-Host "Successfully updated custom property '$PropertyName' on $server."

                }
                else {
                    Write-Error "Failed to update $PropertyName on $server. $PropertyName does not exist." 
                    Continue
                }
            }
            catch {
                Write-Error "Failed to execute SWQL query on $server. Error: $_"
                continue # Skip to the next host if query fails
            }
        }
    
    }

    End {
        # Output the results
        # return $results
    }
}

# Usage
$PropertyName = 'L1Test'
$newvalues = ('Value1','Value2','Value3')

# Add-CustomPropertyValues -Hostname $servers -Username 'loop1' -Password '30DayPassword!' -PropertyName $PropertyName -NewValues $newValues