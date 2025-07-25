# Path to your CSV file
$csvPath = "C:\Users\RWoolsey\OneDrive - Loop1\Documents\Work\Disney Cruises\NodesCaptionBreakdown.csv"

# Import the CSV file
#$data = Import-Csv -Path $csvPath

# Display the imported data
#$data[0..10]

<# SWQL Query for CP's
SELECT 
    nodes.nodeid, 
    nodes.caption,
    nodes.vendor,
    nodes.machinetype,
    nodes.CustomProperties.Department,
    nodes.CustomProperties.Device_Type,
    Nodes.CustomProperties.Device_Function,
    --nodes.sysname,
    --Replace(Replace(nodes.Caption, 'lhp', ''), 'eor', '') AS [NewCaption],
    --nodes.ipaddress,
    SUBSTRING(IPAddress, 1, CHARINDEX('.', IPAddress) - 1) AS [Octet1],
    SUBSTRING(IPAddress, CHARINDEX('.', IPAddress) + 1, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) - CHARINDEX('.', IPAddress) - 1) AS [Octet2],
    SUBSTRING(IPAddress, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) + 1, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) + 1) - CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) - 1) AS Octet3,
    SUBSTRING(IPAddress, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) + 1) + 1, LENGTH(IPAddress)) AS Octet4,
    CASE
        WHEN IPAddress LIKE '10.217%' THEN 'Lighthouse Point'
    END AS [Environment],
        CASE
        WHEN SUBSTRING(IPAddress, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) + 1, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) + 1) - CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) - 1) = '161'
        THEN 'East Orlando'
        WHEN SUBSTRING(IPAddress, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) + 1, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) + 1) - CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) - 1) BETWEEN '163' AND '169'
        THEN 'Lighthouse Point'

    END AS [Location],
nodes.uri
FROM 
    orion.Nodes Nodes
#>

<#
Invokes the Update operation of the CRUD Operations interface and takes three arguments:

SwisConnection (mandatory)
Uri (mandatory, but can be provided from the pipeline)
Properties (mandatory)
Uri identifies the entity you are about to change. The Properties argument accepts a hash table object containing property/value pairs to set in the entity. For example:

Set-SwisObject $swis -Uri 'swis://localhost/Orion/Orion.Nodes/NodeID=1' -Properties @{ Caption = 'New Name' }

To set properties to the same values on multiple objects at the same time, omit the Uri argument and instead, pass the Uri for each entity you want to modify through the PowerShell pipeline. These Uri values can come from a Get-SwisData query or just a list of strings:

# Example passing a list of strings
$uris = @('swis://localhost/Orion/Orion.Nodes/NodeID=3', 'swis://localhost/Orion/Orion.Nodes/NodeID=5', 'swis://localhost/Orion/Orion.Nodes/NodeID=7')
$uris | Set-SwisObject $swis -Properties @{PollInterval=300}

# Example passing Uris from a query
Get-SwisData $swis 'SELECT Uri FROM Orion.Nodes WHERE PollInterval=300' | Set-SwisObject $swis -Properties @{ PollInterval = 120 }
#>

$TestNode = [PSCustomObject]@{
    Ship        = "Lighthouse"
    nodeid      = "12"
    caption     = "eordcl-lhp-dc1-ilo-sw"
    vendor      = "Cisco"
    machinetype = "Cisco Catalyst 9300 Series Switch"
    # Department      = ""
    # Device_Type     = ""
    # Device_Function = ""
    Octet1      = "10"
    Octet2      = "217"
    Octet3      = "161"
    Octet4      = "2"
    # Environment     = "Lighthouse Point"
    # Location        = "East Orlando"
    uri         = "swis://DCLLHPSOLARW01.dcl.wdpr.disney.com/Orion/Orion.Nodes/NodeID=12"
}

$TestNodes = $data[0..100]


# Update the Location CP based off IPAddress
function Set-CustomProperties {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Provide Nodes to update."
        )]
        [array]$Nodes
    )
    
    begin {
        Write-Verbose -Message "Entering the BEGIN block [$($MyInvocation.MyCommand.CommandType): $($MyInvocation.MyCommand.Name)]."

        # Create a table to reference for setting the Environment. This is based on the 2nd octet of the IP Address of the device. 
        $Environment = [PSCustomObject]@{
            '56' = 'Dream'
            '57' = 'Fantasy'
            '58' = 'Magic'
            '59' = 'Wonder'
            '60' = 'Castaway'
            '61' = 'Castaway'
            '217' = 'LightHouse Point'
        }
        
        Write-Verbose -Message "Locations Table: $Locations"
        
    }
    
    process {
        Write-Verbose -Message "Entering the PROCESS block [$($MyInvocation.MyCommand.CommandType): $($MyInvocation.MyCommand.Name)]."

        # Initialize an empty array for UpdateParams
        $UpdateParams = @()
        
        foreach ($node in $Nodes) {

            # Add a new hashtable for each node into the $UpdateParams array
            $UpdateParams += @{
                URI        = $node.uri
                Properties = @{
                    caption         = $node.caption
                    vendor          = $node.vendor
                    machinetype     = $node.machinetype
                    Environment     = $Environment.($node.Octet2)
                }
            }
        }
        
        # Iterate through $UpdateParams to access each element
        foreach ($param in $UpdateParams) {
            Write-Host "URI: $($param.URI)" -ForegroundColor Magenta
            Write-Host "Caption: $($node.caption)" -ForegroundColor green
            Write-Host "Vendor: $($node.vendor)" -ForegroundColor green
            Write-Host "MachineType: $($node.machinetype)" -ForegroundColor green
            Write-Host "Environment: $($param.Properties.Environment)" -ForegroundColor green
        }
        
        # Example: Access properties for the first node in $UpdateParams
        if ($TestNodes[0].Department -ne '') { 
            $UpdateParams[0].Properties['Department'] = $TestNodes[0].Department
            Write-Verbose "Updating node $($TestNodes[0].caption) with properties: Location = $($UpdateParams[0].Properties.Location)"
            # Uncomment the line below to apply the update with Set-SwisObject
            # Set-SwisObject -SwisConnection $SwisConnection -Uri $UpdateParams[0].URI -Properties $UpdateParams[0].Properties
        }
        
    }
    
    end {
        Write-Verbose -Message "Entering the END block [$($MyInvocation.MyCommand.CommandType): $($MyInvocation.MyCommand.Name)]."

        Write-Verbose -Message "End"

    }
}

