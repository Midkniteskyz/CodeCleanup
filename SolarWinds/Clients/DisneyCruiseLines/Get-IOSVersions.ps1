function Get-IOSVersion {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER Hostname
        An array of one or more hostnames for SolarWinds servers. If this parameter is not provided, the function will attempt to read the hostnames from a 'servers.txt' file located in the script's root directory.

    .PARAMETER Username
        The username for authenticating the connection to the SolarWinds Information Service (SWIS).

    .PARAMETER Password
        The password associated with the provided username for connecting to the SolarWinds Information Service (SWIS).

    .EXAMPLE

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
            ValueFromPipelineByMachineType = $true,
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
        [string]$MachineType
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

        # Build the dynamic WHERE clause if MachineType is provided
        $whereClause = ""
        if ($MachineType) {
            if ($MachineType -like '*`*') {
                # Handle case where MachineType contains a wildcard
                $whereClause = ("`nWHERE " + ($MachineType.Replace('*', '%') | ForEach-Object { "CP.Field LIKE '$_'" })).TrimEnd(' OR')
                Write-Verbose -Message "Wildcard detected. WHERE clause: $whereClause"
            } else {
                # Handle exact matches
                $whereClause = ("`nWHERE " + ($MachineType | ForEach-Object { "CP.Field = '$_'" })).TrimEnd(' OR')
                Write-Verbose -Message "No wildcard detected. WHERE clause: $whereClause"
            }
        }

        # Define the base SWQL query
        $baseQuery = @"
SELECT n.Caption, n.IPAddress, n.MachineType, n.IOSVersion, n.HardwareHealthInfos.ServiceTag 
FROM Orion.Nodes as n 
WHERE MachineType LIKE
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
            return $results | Select-Object Caption, IPAddress, MachineType, IOSVersion, ServiceTag | Out-GridView
        } else {
            Write-Host "No results found for the custom property $MachineType."
        }
    }
}

# Get-IOSVersion -Hostname $servers -Username $Username -Password $Password -MachineType "Cisco"