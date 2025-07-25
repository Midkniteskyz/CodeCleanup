function Get-SolarWindsGroups {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $SwisConnection,

        [Parameter(Mandatory = $false)]
        [string]$Name
    )

    <#
    .SYNOPSIS
        Retrieves groups from a SolarWinds Orion server.

    .DESCRIPTION
        This function connects to a specified SolarWinds Orion server and retrieves group information,
        including container IDs and names, using the SolarWinds Information Service (SWIS).

    .PARAMETER Hostname
        The hostname or IP address of the SolarWinds Orion server.

    .PARAMETER Username
        The username used for authentication with the SolarWinds server.

    .PARAMETER Password
        The password used for authentication with the SolarWinds server.

    .EXAMPLE
        PS> Get-Groups -Hostname "solarwinds" -Username "user" -Password "password"
    #>

    try {

        $whereClause = ""
        if ($Name) {
            if ($Name -like '*`*') {
                # Handle case where Name contains a wildcard
                $whereClause = "`nWHERE " + (($Name.Replace('*', '%') | ForEach-Object { "Name LIKE '$_'" }) -join " OR ")
                Write-Verbose "Wildcard detected. WHERE clause: $whereClause"
            } else {
                # Handle exact matches
                $whereClause = "`nWHERE " + (($Name | ForEach-Object { "`nName = '$_'" }) -join " OR ")
                Write-Verbose "No wildcard detected. WHERE clause: $whereClause"
            }
        }

        # Define the base SWQL query
        $baseQuery = @"
SELECT
  ContainerID AS IDNumber,
  CASE WHEN NAME = DisplayName THEN NAME ELSE DisplayName END AS [Name]
FROM
  Orion.Container
"@ + $whereClause

        # Execute the query
        Get-SwisData -SwisConnection $SwisConnection -Query $baseQuery
    }
    catch {
        Write-Error "An error occurred: $($_.Exception.Message)"
    }
}

function New-SolarWindsGroup {
    <#
        .EXAMPLE 
        Filter samples w/ all operators:

        IP_Address is 192.168.10.10
        filter:/Orion.Nodes[IP_Address='192.168.10.10')]

        IP_Address is not 192.168.10.10
        filter:/Orion.Nodes[IP_Address!='192.168.10.10']

        IP_Address starts with 192.168.10.
        filter:/Orion.Nodes[StartsWith(IP_Address,'192.168.10.')]

        IP_Address ends with .10.%
        filter:/Orion.Nodes[EndsWith(IP_Address,'.10.%')]

        IP_Address contains .10.
        filter:/Orion.Nodes[Contains(IP_Address,'.10.')]

        IP_Address matches 192.168.*
        filter:/Orion.Nodes[Pattern(IP_Address,'192.168.%')]
    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory = $true)]
        $SwisConnection,

        [Parameter(Mandatory = $true)]
        [string]$GroupName,

        [Parameter(Mandatory = $false)]
        [string]$Owner = "Core",

        [Parameter(Mandatory = $false)]
        [int]$RefreshFrequency = 60,

        [Parameter(Mandatory = $false)]
        [ValidateSet("MixedShowsWarning", "ShowWorstStatus", "ShowBestStatus")]
        [string]$StatusCalculator = "MixedShowsWarning",

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet("true", "false")]
        [bool]$PollingEnabled = $true,

        [Parameter(Mandatory = $true)]
        [array]$Filter
    )

    # Mapping descriptive words to integers
    switch ($StatusCalculator) {
        "MixedShowsWarning" { $statusCalcValue = 0 }
        "ShowWorstStatus" { $statusCalcValue = 1 }
        "ShowBestStatus" { $statusCalcValue = 2 }
    }

    # Convert member definitions to XML
    $xmlMembers = "<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>"
    foreach ($member in $Filter) {
        $xmlMembers += "<MemberDefinitionInfo><Name>$($member.Name)</Name><Definition>$($member.Definition)</Definition></MemberDefinitionInfo>"
    }
    $xmlMembers += "</ArrayOfMemberDefinitionInfo>"

    # Invoke the SWIS API to create a new container
    $groupId = Invoke-SwisVerb $SwisConnection "Orion.Container" "CreateContainer" @(
        $GroupName, 
        $Owner, 
        $RefreshFrequency, 
        $statusCalcValue, 
        $Description, 
        $PollingEnabled, 
        ([xml]$xmlMembers).DocumentElement
    )

    Write-Output "Group created with ID: $groupId"
}

function Remove-SolarWindsGroup {
    <#
        .SYNOPSIS
            Deletes one or more groups from a SolarWinds Orion server.

        .DESCRIPTION
            This function deletes groups specified by their group ID from a SolarWinds Orion server,
            using credentials provided for authentication.

        .PARAMETER GroupId
            The ID of the group to be deleted. This parameter accepts an array of integers.

        .PARAMETER Hostname
            The hostname or IP address of the SolarWinds Orion server.

        .PARAMETER Username
            The username used for authentication with the SolarWinds server.

        .PARAMETER Password
            The password used for authentication with the SolarWinds server.

        .EXAMPLE
            PS> 12345 | Remove-SolarWindsGroup -Hostname "server01" -Username "admin" -Password "pass"
            Deletes the group with ID 12345 from the SolarWinds server at "server01".

        .EXAMPLE
            PS> Get-Groups -Hostname "server01" -Username "admin" -Password "pass" | Remove-SolarWindsGroup -Hostname "server01" -Username "admin" -Password "pass"
            Retrieves groups from the SolarWinds server and deletes them.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [int[]]$GroupId,

        [Parameter(Mandatory = $true)]
        $SwisConnection
    )

    Begin {
        # Optional pre formatting code can be added here
    }

    Process {
        foreach ($id in $GroupId) {
            try {
                # Invoke the SWIS API to delete the specified container
                Write-Verbose "Deleting group with ID: $id"
                Invoke-SwisVerb $SwisConnection "Orion.Container" "DeleteContainer" @($id) | Out-Null
                Write-Output "Deleted group with ID: $id"
            }
            catch {
                Write-Error "Failed to delete group with ID $id : $($_.Exception.Message)"
            }
        }
    }

    End {
        # Optional cleanup code can be added here
    }
}

function Get-FloorNumberFromCaption {
    param (
        [Parameter(Mandatory = $true)]
        $SwisConnection
    )
    
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
                NodeID = $node.NodeID
                Caption = $node.Caption
                # SystemName = $node.Sysname
                ExtractedDigits = $matches[1] # $matches[1] refers to the first capture group
            }
        }
    }
    
    # Extract the first digit of each number, ensure uniqueness, and sort them
    $uniqueFirstDigits = $extractedDigits.ExtractedDigits | ForEach-Object {
        # Convert the number to a string and get the first character
        $_.ToString().Substring(0,1)
    } | Sort-Object -Unique
    
    # Display the unique first digits
    return $uniqueFirstDigits

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
        [Parameter(Mandatory = $false, HelpMessage = "Enter one or more hostnames for the SolarWinds server(s). Defaults to 'localhost' if none provided.")]
        [string[]]$Hostname = @('localhost'),

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
                $floors = Get-FloorNumberFromCaption -SwisConnection $swis
                $floors | ForEach-Object {
                    $floor = $_
                    Write-Verbose "Processing floor: $floor"
                    $filter = @(
                        @{
                            Name = "Zone $floor";
                            Definition = "filter:/Orion.Nodes[Pattern(Caption,'%-$floor[0-9][0-9][^0-9]%')]"
                        }
                    )
                    New-SolarWindsGroup -SwisConnection $swis -GroupName "Zone $floor" -Description "Zone $floor Group" -Filter $filter
                }
            } catch {
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


# Specify the hostname, username, and plain text password
# $hostname = "dclwdrsolarw01"
# $hostname = "dclmagsolarw01"
# $hostname = "dclwshsolarw01" # dclwshsolarw01 / 10.60.15.200
# $hostname = "dclfsysolarw01"
 $hostname = "dcldrmsolarw01"
$username = "loop1"
$plainTextPassword = '30DayPassword!'

# Convert the plain text password to a SecureString
$password = New-Object System.Security.SecureString
$plainTextPassword.ToCharArray() | ForEach-Object { $password.AppendChar($_) }

# Create a PSCredential object
$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

# Connect to SWIS
$swis = Connect-Swis -host $hostname -cred $cred

# Uncomment this to require credential input. 
# $creds = Get-Credential  # display a window asking for credentials
# $swis = Connect-Swis -Credential $creds -Hostname localhost  # create a SWIS connection object

<# Example usage of a filter
$members = @(
    @{
     Name = "TestDev"; Definition = "filter:/Orion.Nodes[Pattern(SysName,'%-4[0-9][0-9][^0-9]%') AND Pattern(Caption,'%-4[0-9][0-9][^0-9]%')]" 
    }
)
#>

# New-SolarWindsGroup -SwisConnection $swis -GroupName "Sample PowerShell Group"  -Description "Group created by the PowerShell sample script." -Filter $members

# Get-SolarWindsGroups -SwisConnection $swis -Name "*zone*"

# Remove-SolarWindsGroup -SwisConnection $swis -GroupId (Get-SolarWindsGroups -SwisConnection $swis -Name "*zone*").idnumber

# Get-FloorNumberFromCaption -SwisConnection $swis

# Invoke-CreateNewGroupsBasedOnFloorNumberInCaption -Hostname $hostname -Username $username -Password $plainTextPassword -Verbose