function Get-IOSVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]]$Hostname,

        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string]$Password,

        [Parameter(Mandatory = $false)]
        [string]$MachineType,

        [Parameter(Mandatory = $false)]
        [string]$OutputCSV
    )

    <#
    .SYNOPSIS
        Retrieves IOS version information from SolarWinds based on the specified machine type.

    .DESCRIPTION
        This function connects to one or more SolarWinds servers and retrieves IOS version and related information for devices based on the machine type. The results can be optionally exported to a CSV file.

    .PARAMETER Hostname
        An array of hostnames for the SolarWinds servers. If this parameter is not provided, the function will attempt to read the hostnames from a 'servers.txt' file located in the script's root directory.

    .PARAMETER Username
        The username used for authenticating the connection to the SolarWinds Information Service (SWIS).

    .PARAMETER Password
        The password associated with the provided username for connecting to SWIS.

    .PARAMETER MachineType
        The type of machine to filter by when retrieving IOS version information.

    .PARAMETER OutputCSV
        Specifies the path to save the output CSV file. If not provided, no CSV file will be created.

    .EXAMPLE
        PS> Get-IOSVersion -Username "admin" -Password "password" -MachineType "Cisco"

    .NOTES
        Version: 1.1
        Author: Ryan Woolsey
        Date: 9-17-2024
    #>

    Begin {
        Write-Verbose "Starting the function."

        # Load server hostnames if not provided
        if (-not $Hostname) {
            $Hostname = Get-Content "$PSScriptRoot\servers.txt"
            Write-Verbose "Loaded hostnames from file."
        }

        $results = @()
    }

    Process {
        foreach ($server in $Hostname) {
            Write-Verbose "Processing server: $server"
            try {
                $swis = Connect-Swis -Hostname $server -UserName $Username -Password $Password
                $query = "SELECT Caption, IPAddress, MachineType, IOSVersion FROM Orion.Nodes WHERE MachineType LIKE '$MachineType'"
                $data = Get-SwisData -SwisConnection $swis -Query $query
                $results += $data
                Write-Verbose "Data retrieved from $server."
            } catch {
                Write-Warning "Failed to connect or retrieve data from $server : $_"
            }
        }
    }

    End {
        Write-Verbose "Finishing up the function."
        if ($OutputCSV -and $results) {
            $results | Export-Csv -Path $OutputCSV -NoTypeInformation
            Write-Host "Results exported to CSV at $OutputCSV"
        } elseif ($results) {
            $results | Out-GridView -Title "IOS Version Information"
        } else {
            Write-Host "No results found."
        }
    }
}
