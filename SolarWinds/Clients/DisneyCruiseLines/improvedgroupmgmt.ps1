function Get-SolarWindsGroups {
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Low'
    )]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = "Enter one or more hostnames for the SolarWinds server(s). If not provided, servers will be read from servers.txt."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('ComputerName', 'Server')]
        [string[]]$Hostname,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = "Enter the username for the SWIS connection."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('User')]
        [string]$Username,

        [Parameter(
            Mandatory = $true,
            Position = 2,
            HelpMessage = "Enter the password for the SWIS connection."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Pass')]
        [string]$Password,

        [Parameter(
            Mandatory = $false,
            Position = 3,
            HelpMessage = "Filter groups by name. Supports wildcards (*)."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('GroupName', 'Filter')]
        [string]$Name
    )

    begin {
        <#
        .SYNOPSIS
            Retrieves groups from SolarWinds Orion servers.

        .DESCRIPTION
            The Get-SolarWindsGroups function connects to one or more SolarWinds Orion servers
            and retrieves group information using the SolarWinds Information Service (SWIS).
            It supports filtering by name, wildcards, and can handle multiple servers.

        .PARAMETER Hostname
            One or more hostnames or IP addresses of SolarWinds Orion servers.
            If not provided, the function will attempt to read server names from servers.txt in the current directory.

        .PARAMETER Username
            The username used for authentication with the SolarWinds server.
            Must have appropriate permissions to query container information.

        .PARAMETER Password
            The password used for authentication with the SolarWinds server.
            Should be provided as a SecureString for enhanced security.

        .PARAMETER Name
            Optional filter to search for specific groups. Supports wildcards (*).
            Example: "Windows*" will return all groups starting with "Windows"

        .EXAMPLE
            PS> Get-SolarWindsGroups -Hostname "solarwinds01" -Username "admin" -Password $securePassword
            Retrieves all groups from the specified SolarWinds server.

        .EXAMPLE
            PS> Get-SolarWindsGroups -Hostname "sw01","sw02" -Username "admin" -Password $securePassword -Name "Windows*"
            Retrieves Windows-related groups from multiple SolarWinds servers.

        .EXAMPLE
            PS> "sw01","sw02" | Get-SolarWindsGroups -Username "admin" -Password $securePassword 
            Demonstrates pipeline input of hostnames

        .NOTES
            Author: Ryan Woolsey
            Version: 2.0
            Last Modified: 2024-10-25
            Requires: PowerShell 5.1 or later
            Dependencies: SolarWinds.Orion.Core.ConnectionSettings

        .LINK
            https://documentation.solarwinds.com/
        #>

        # Initialize results array
        $results = @()

        if (-not $Hostname) {
            if (Test-Path "servers.txt") {
                $Hostname = Get-Content "servers.txt" | Where-Object { $_ -match '\S' }
                Write-Verbose "Loaded $(($Hostname | Measure-Object).Count) servers from servers.txt"
            }
            else {
                throw "No hostname provided and servers.txt not found in current directory"
            }
        }
    }

    process {
        foreach ($h in $Hostname) {
            Write-Verbose "Processing server: $h"

            # Create connection parameters
            $swisParams = @{
                Hostname = $h
                Username = $Username
                Password = $Password
            }

            # Attempt to connect to SWIS
            try {
                Write-Host "Connecting to $h..." -ForegroundColor Yellow
                $swis = Connect-Swis @swisParams
                Write-Host "Successfully connected to $h" -ForegroundColor Green
                Write-Verbose "SWIS connection established to $h"
            }
            catch {
                Write-Error "Failed to connect to $h. Error: $_"
                continue # Skip to next host if connection fails
            }

            try {
                # Build WHERE clause for filtering
                $whereClause = ""
                if ($Name) {
                    if ($Name -like '*`*') {
                        # Handle wildcards in name filter
                        $whereClause = "`nWHERE " + (($Name.Replace('*', '%') | 
                                ForEach-Object { "Name LIKE '$_'" }) -join " OR ")
                        Write-Verbose "Applied wildcard filter: $whereClause"
                    }
                    else {
                        # Handle exact name matches
                        $whereClause = "`nWHERE " + (($Name | 
                                ForEach-Object { "Name = '$_'" }) -join " OR ")
                        Write-Verbose "Applied exact name filter: $whereClause"
                    }
                }

                # Construct SWQL query with optional result limiting
                $baseQuery = @"
SELECT
  ContainerID AS IDNumber,
  CASE WHEN NAME = DisplayName THEN NAME ELSE DisplayName END AS [Name]
FROM
  Orion.Container
"@ + $whereClause

                Write-Verbose "Executing query: $baseQuery"

                # Execute query and process results
                $queryResults = Get-SwisData -SwisConnection $swis -Query $baseQuery

                # Add server information to results
                $queryResults | ForEach-Object {
                    $_ | Add-Member -MemberType NoteProperty -Name 'Server' -Value $h
                    $results += $_
                }

                Write-Verbose "Retrieved $($queryResults.Count) groups from $h"
            }
            catch {
                Write-Error "Query execution failed on $h. Error: $_"
            }
            finally {
                # Cleanup 

            }
        }
    }

    end {
        # Return results
        Write-Verbose "Total groups retrieved: $($results.Count)"
        return $results
    }
}

function New-SolarWindsGroup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = "Enter one or more hostnames for the SolarWinds server(s). If not provided, servers will be read from servers.txt."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('ComputerName', 'Server')]
        [string[]]$Hostname,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = "Enter the username for the SWIS connection."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('User')]
        [string]$Username,

        [Parameter(
            Mandatory = $true,
            Position = 2,
            HelpMessage = "Enter the password for the SWIS connection."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Pass')]
        [string]$Password,

        [Parameter(
            Mandatory = $true,
            Position = 3,
            HelpMessage = "Name of the group to create"
        )]
        [ValidateNotNullOrEmpty()]
        [string]$GroupName,

        [Parameter(
            Mandatory = $false,
            Position = 4,
            HelpMessage = "Owner of the group"
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Owner = "Core",

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Refresh frequency in seconds"
        )]
        [ValidateRange(30, 86400)]
        [int]$RefreshFrequency = 60,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Status calculation method for the group"
        )]
        [ValidateSet(
            "MixedShowsWarning", 
            "ShowWorstStatus", 
            "ShowBestStatus"
        )]
        [string]$StatusCalculator = "MixedShowsWarning",

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Description of the group"
        )]
        [string]$Description,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Enable or disable polling for the group"
        )]
        [bool]$PollingEnabled = $true,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "Array of filter definitions"
        )]
        [ValidateNotNullOrEmpty()]
        [array]$Filter,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Automatically refresh group after creation"
        )]
        [switch]$AutoRefresh
    )

    begin {
        <#
        .SYNOPSIS
            Creates a new group in SolarWinds Orion with specified filters and settings.

        .DESCRIPTION
            The New-SolarWindsGroup function creates a new group in SolarWinds Orion using the SWIS API.
            It supports various filter types, status calculation methods, and group settings.

        .PARAMETER SwisConnection
            Active SWIS connection object from Connect-Swis.

        .PARAMETER GroupName
            Name for the new group.

        .PARAMETER Owner
            Owner of the group. Defaults to "Core".

        .PARAMETER RefreshFrequency
            How often the group should refresh in seconds. Valid range: 30-86400 (24 hours).
            Defaults to 60 seconds.

        .PARAMETER StatusCalculator
            Method to calculate group status:
            - MixedShowsWarning: Show warning if mixed statuses exist
            - ShowWorstStatus: Show the worst status among members
            - ShowBestStatus: Show the best status among members

        .PARAMETER Description
            Optional description for the group.

        .PARAMETER PollingEnabled
            Enable or disable polling for the group. Defaults to true.

        .PARAMETER Filter
            Array of filter definitions. Each filter should contain Name and Definition properties.
            See examples for filter syntax.

        .PARAMETER AutoRefresh
            If specified, automatically refreshes the group after creation.

        .EXAMPLE
            $filters = @(
                @{
                    Name = "Windows Servers"
                    Definition = "filter:/Orion.Nodes[Pattern(IP_Address,'192.168.%')]"
                }
            )
            New-SolarWindsGroup --Hostname "solarwinds01" -Username "admin" -Password $securePassword -GroupName "Windows Servers" -Filter $filters

        .EXAMPLE
            $filters = @(
                @{
                    Name = "Critical Servers"
                    Definition = "filter:/Orion.Nodes[Status=2]"
                }
            )
            New-SolarWindsGroup -Hostname "solarwinds01" -Username "admin" -Password $securePassword -GroupName "Critical Servers" `
                               -StatusCalculator ShowWorstStatus -Filter $filters `
                               -Description "Servers in critical state" -AutoRefresh

        .NOTES
            Filter Operator Examples:
            - Equals:         [IP_Address='192.168.10.10']
            - Not Equals:     [IP_Address!='192.168.10.10']
            - Starts With:    [StartsWith(IP_Address,'192.168.10.')]
            - Ends With:      [EndsWith(IP_Address,'.10')]
            - Contains:       [Contains(IP_Address,'.10.')]
            - Pattern Match:  [Pattern(IP_Address,'192.168.%')]

            To figure out how a filter is constructed, run this query on the following webpage.

            Query:
            SELECT Name, Expression, Definition
            FROM Orion.ContainerMemberDefinition
            where name like '%<name of group your interested in>%'

            Webpage:
            https://<solarwinds url>/orion/admin/swis.aspx

            Take the definition are the filter

            Author: Ryan Woolsey
            Version: 2.0
            Last Modified: 2024-10-25
            Requires: SolarWinds.Orion.Core.ConnectionSettings
        #>

        # If no hostname provided, try to read from servers.txt
        if (-not $Hostname) {
            if (Test-Path "servers.txt") {
                $Hostname = Get-Content "servers.txt" | Where-Object { $_ -match '\S' }
                Write-Verbose "Loaded $(($Hostname | Measure-Object).Count) servers from servers.txt"
            }
            else {
                throw "No hostname provided and servers.txt not found in current directory"
            }
        }
    }

    process {
        foreach ($h in $Hostname) {
            Write-Verbose "Processing server: $h"

            # Create connection parameters
            $swisParams = @{
                Hostname = $h
                Username = $Username
                Password = $Password
            }

            # Attempt to connect to SWIS
            try {
                Write-Host "Connecting to $h..." -ForegroundColor Yellow
                $swis = Connect-Swis @swisParams
                Write-Host "Successfully connected to $h" -ForegroundColor Green
                Write-Verbose "SWIS connection established to $h"
            }
            catch {
                Write-Error "Failed to connect to $h. Error: $_"
                continue # Skip to next host if connection fails
            }

            try {
                Write-Verbose "Creating group '$GroupName' with $(($Filter).Count) filter(s)"

                # Map status calculator to integer value
                $statusCalcValue = switch ($StatusCalculator) {
                    "MixedShowsWarning" { 0 }
                    "ShowWorstStatus" { 1 }
                    "ShowBestStatus" { 2 }
                }

                # Validate filter structure
                foreach ($f in $Filter) {
                    if (-not ($f.Name -and $f.Definition)) {
                        throw "Invalid filter structure. Each filter must have 'Name' and 'Definition' properties."
                    }
                }

                # Convert member definitions to XML
                $xmlMembers = "<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>"
                foreach ($member in $Filter) {
                    $xmlMembers += "<MemberDefinitionInfo><Name>$($member.Name)</Name><Definition>$($member.Definition)</Definition></MemberDefinitionInfo>"
                }
                $xmlMembers += "</ArrayOfMemberDefinitionInfo>"

                # Invoke the SWIS API to create a new container
                $groupId = Invoke-SwisVerb $Swis "Orion.Container" "CreateContainer" @(
                    $GroupName, 
                    $Owner, 
                    $RefreshFrequency, 
                    $statusCalcValue, 
                    $Description, 
                    $PollingEnabled, 
                    ([xml]$xmlMembers).DocumentElement
                )

                Write-Host "Successfully created $GroupName group on $h." -ForegroundColor Green

            }
            catch {
                $errorMessage = "Failed to create group '$GroupName': $($_.Exception.Message)"
                Write-Error $errorMessage
                throw $errorMessage
            }
        }
    }
}

function Remove-SolarWindsGroup {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = "Enter one or more hostnames for the SolarWinds server(s)."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('ComputerName', 'Server')]
        [string[]]$Hostname,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = "Enter the username for the SWIS connection.",
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('User')]
        [string]$Username,

        [Parameter(
            Mandatory = $true,
            Position = 2,
            HelpMessage = "Enter the password for the SWIS connection.",
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Pass')]
        [string]$Password,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [int[]]$IDNumber,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Filter groups by name. Supports wildcards (*)."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('GroupName', 'Filter')]
        [string]$Name

    )
    Begin {

        if (-not $Hostname) {
            if (Test-Path "servers.txt") {
                $Hostname = Get-Content "servers.txt" | Where-Object { $_ -match '\S' }
                Write-Verbose "Loaded $(($Hostname | Measure-Object).Count) servers from servers.txt"
            }
            else {
                throw "No hostname provided and servers.txt not found in current directory"
            }
        }

    }

    Process {
        foreach ($h in $Hostname) {
            <# $currentItemName is the current item #>
            # Create connection parameters
            $swisParams = @{
                Hostname = $h
                Username = $Username
                Password = $Password
            }

            # Attempt to connect to SWIS
            try {
                Write-Host "Connecting to $h..." -ForegroundColor Yellow
                $swis = Connect-Swis @swisParams
                Write-Host "Successfully connected to $h" -ForegroundColor Green
                Write-Verbose "SWIS connection established to $h"

                if ($name) {
                    
                    $IDNumber = (Get-SolarWindsGroups -Hostname $h -Username $Username -Password $Password -Name $Name).IDNumber

                    foreach ($id in $IDNumber) {
                        if ($PSCmdlet.ShouldProcess("Group ID: $id", "Remove")) {
                            try {
                                # Invoke the SWIS API to delete the specified container
                                Write-Verbose "Deleting group with ID: $id"
                                Invoke-SwisVerb $Swis "Orion.Container" "DeleteContainer" @($id) | Out-Null
                                Write-Output "Deleted group with ID: $id"
                                Write-Host "Deleted $Name on $h"
                            }
                            catch {
                                Write-Error "Failed to delete group with ID $id : $($_.Exception.Message)"
                            }
                        }
                    }

                }
                if ($IDNumber) {

                    foreach ($id in $IDNumber) {

                        try {
                            # Invoke the SWIS API to delete the specified container
                            Write-Verbose "Deleting group with ID: $id"
                            Invoke-SwisVerb $Swis "Orion.Container" "DeleteContainer" @($id) | Out-Null
                            Write-Output "Deleted group with ID: $id"
                        }
                        catch {
                            Write-Error "Failed to delete group with ID $id : $($_.Exception.Message)"
                        }

                    }

                }


            }
            catch {
                Write-Error "Failed to connect to $h. Error: $_"
                continue # Skip to next host if connection fails
            }
        }
    }

}

function Get-FloorNumberFromCaption {
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = "Enter one or more hostnames for the SolarWinds server(s)."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('ComputerName', 'Server')]
        [string]$Hostname,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = "Enter the username for the SWIS connection.",
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('User')]
        [string]$Username,

        [Parameter(
            Mandatory = $true,
            Position = 2,
            HelpMessage = "Enter the password for the SWIS connection.",
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Pass')]
        [string]$Password
    )
    
    Write-Host "Connecting to $Hostname..."

    # Attempt to connect to SWIS
    try {
        $swis = Connect-Swis -Hostname $Hostname -Username $Username -Password $Password

        if ($swis) {
            Write-Host "Successfully connected to $Hostname" -ForegroundColor Green
            Write-Verbose "Connection to $Hostname established."

            try {
                
                # Query to get captions
                $query = "SELECT NodeID, Caption, Sysname FROM Orion.Nodes WHERE Caption LIKE '%[0-9][0-9][0-9]%'"
                $nodes = Get-SwisData $swis $query
                
                # Regex to find exactly three consecutive digits
                # $regex = '\b(\d{3})\b' # \b is a word boundary, ensuring digits are isolated
                # $regex = '(\d{3})(?!\d)'
                $regex = '(?<!\d)(\d{3})(?!\d)'
                
                # Iterate through each node and extract digits
                $extractedDigits = foreach ($node in $nodes) {
                    if ($node.Caption -match $regex) {
                        # Capture and output the digits
                        [PSCustomObject]@{
                            NodeID          = $node.NodeID
                            Caption         = $node.Caption
                            # SystemName = $node.Sysname
                            ExtractedDigits = $matches[1] # $matches[1] refers to the first capture group
                        }
                    }
                }
            
                # Extract the first digit of each number, ensure uniqueness, and sort them
                $uniqueFirstDigits = $extractedDigits.ExtractedDigits | ForEach-Object {
                    # Convert the number to a string and get the first character
                    $_.ToString().Substring(0, 1)
                } | Sort-Object -Unique
            
                # Display the unique first digits
                return $uniqueFirstDigits

            }
            catch {
                Write-Error "Failed to parse hostnames to $Hostname. Error: $_"
            }
        }
        
    }
    catch {
        Write-Error "Failed to connect to $Hostname. Error: $_"
        continue # Skip to the next host if connection fails
    }
}

# Premade Tasks
function Invoke-CreateNewGroupsBasedOnFloorNumberInCaption {
    [CmdletBinding()]

    <#
        .SYNOPSIS
            Automatically creates new groups based on the floor number extracted from node captions in SolarWinds.

        .DESCRIPTION
            Connects to one or more SolarWinds servers to gather node captions. It parses floor numbers from the captions,
            creating unique groups for each floor.

        .EXAMPLE
            PS> Invoke-CreateNewGroupsBasedOnFloorNumberInCaption -Username "admin" -Password "password"

        .NOTES
            Ensure that the function 'Get-FloorNumberFromCaption' and 'New-SolarWindsGroup' are correctly implemented
            and available in the session or script.
    #>

    param (
        [Parameter(Mandatory = $false, HelpMessage = "Enter one or more hostnames for the SolarWinds server(s). Defaults to servers.txt if none provided.")]
        [string[]]$Hostname,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the username for the SWIS connection.")]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the password for the SWIS connection.")]
        [ValidateNotNullOrEmpty()]
        [string]$Password
    )

    Begin {
        # Convert the plain text password to a SecureString
        $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        # Create a PSCredential object
        $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $Username, $securePassword

        # Function to process each server
        function Process-Server($serverName) {
            Write-Verbose "Attempting connection to $serverName."
            try {
                $swis = Connect-Swis -host $serverName -cred $cred
                Write-Verbose "Connection to $serverName successful."

                # Get the floors
                $floors = Get-FloorNumberFromCaption -Hostname $serverName -Username $Username -Password $Password
                $floors | ForEach-Object {
                    $floor = $_
                    Write-Verbose "Processing floor: $floor"
                    $filter = @(
                        @{
                            Name       = "Zone $floor";
                            Definition = "filter:/Orion.Nodes[Pattern(Caption,'%-$floor[0-9][0-9][^0-9]%')]"
                        }
                    )
                    New-SolarWindsGroup -Hostname $serverName -Username $Username -Password $Password -GroupName "Zone $floor" -Description "Zone $floor Group" -Filter $filter
                }
            }
            catch {
                Write-Error "Failed to process server $serverName : $_"
            }
        }
    }

    Process {
        foreach ($h in $Hostname) {
            Process-Server -serverName $h
        }
    }

    End {
        Write-Verbose "Completed processing all specified servers."
    }
}


# Get the all groups from all servers in the servers.txt file
# Get-SolarWindsGroups -Username "<username>" -Password "<password>"

# Get the all groups that match the word "zone" from all servers in the servers.txt file
# Get-SolarWindsGroups -Username "<username>" -Password "<password>" -Name "*zone*"

# Get groups that start with RDP from dcldrmsolarw01
# Get-SolarWindsGroups -Hostname "<hostname>" -Username "<username>" -Password "<password>" -Name "rdp*"

# Create a new solarwinds group

# Example usage of a filter
$filter = @(
    @{
     Name = "TestDevGroup"; 
     Definition = "filter:/Orion.Nodes[Contains(Caption,'AMX')]" 
    }
)


# Create a group named "Testing Group" and add a dynamic filter named TestDevGroup looking for captions with AMX
# New-SolarWindsGroup -Hostname "dclwdrsolarw01" -Username $Username -Password $password -GroupName "Testing Group" -Filter $filter

# Remove a group named "Testing Group"
# Remove-SolarWindsGroup -Hostname $hostname -Username $Username -Password $password -Name "Testing Group"

# Remove a group with the id number of 58
# Remove-SolarWindsGroup -Hostname $hostname -Username $Username -Password $password -IDNumber 58

# Get the floor number by parsing the hostname of a node
# Get-FloorNumberFromCaption -Hostname $hostname -Username $Username -Password $password

# Create groups Based on the parsed hostname
# Invoke-CreateNewGroupsBasedOnFloorNumberInCaption -Hostname $hostname -Username $Username -Password $password