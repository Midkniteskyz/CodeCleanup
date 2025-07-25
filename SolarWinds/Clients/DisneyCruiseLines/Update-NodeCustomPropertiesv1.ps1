# This sample script demonstrates how to set a custom property of a node
# or an interface using CRUD operations.
#
# Please update the hostname and credential setup to match your configuration, and
# reference to an existing node and interface which custom property you want to set.

# Connect to SWIS
$hostname = "DCLADVSOLARW01"
$username = "Loop1"
$password = "30DayPassword!"
$swis = Connect-Swis -host $hostname -UserName $username -Password $password

$swqlQuery = @"
SELECT
    n.ip_address,
    n.caption,
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            SubString(
                                REPLACE(
                                    CASE
                                        WHEN n.caption LIKE '%eordcl-adv-dst-%' THEN REPLACE(n.Caption, 'eordcl-adv-dst-', '')
                                        WHEN n.caption LIKE '%eordcl-adv-ra-%' THEN REPLACE(n.Caption, 'eordcl-adv-ra-', '')
                                        WHEN n.caption LIKE '%eordcl-adv-dc-%' THEN REPLACE(n.Caption, 'eordcl-adv-dc-', '')
                                        WHEN n.caption LIKE '%eordcl-adv-c-%' THEN REPLACE(n.Caption, 'eordcl-adv-c-', '')
                                        WHEN n.caption LIKE '%eordcl-adv-%' THEN REPLACE(n.Caption, 'eordcl-adv-', '')
                                        WHEN n.caption LIKE '%dcladv%' THEN REPLACE(n.Caption, 'dcladv', '')
                                        ELSE caption
                                    END,
                                    '.dcl.wdpr.disney.com',
                                    ''
                                ),
                                1,
                                5
                            ),
                            'UC',
                            'DC'
                        ),
                        'IT',
                        'DC'
                    ),
                    'AD',
                    'DC'
                ),
                'DB',
                'DC'
            ),
            'P',
            'P.'
        ),
        'S',
        'S.'
    ) AS [Parsed_RDP],
    n.CustomProperties.RDP,
    CASE
        WHEN n.caption LIKE '%-mto-%' THEN 'MTO'
        WHEN n.caption LIKE '%-ent-%' THEN 'Entertainment'
        ELSE 'IT'
    END AS [Parsed_Department],
    n.CustomProperties.Department,
    --n.CustomProperties.Device_Function,
    --n.CustomProperties.Device_Type,
    --n.CustomProperties.deviceType,
    --n.CustomProperties.DeviceVendor,
    --n.MachineType,
    --n.vendor,
    --n.CustomProperties.Access_ROOM_RDP,
    --n.CustomProperties.Device_Grouping,
    --n.CustomProperties.environment,
    --n.CustomProperties.Infrastructure,
    --n.CustomProperties.Hardware_Definition,
    --n.sysname,
    --n.CustomProperties.SerialNumber,
    --n.CustomProperties.SupportEmail
    --n.uri
    n.NodeId
FROM
    orion.nodes AS n
WHERE
    n.MachineType != 'Cisco Catalyst C9200CX-12P-2X2G'
    AND caption LIKE '%[0-9][0-9][0-9][a-zA-Z]%'
ORDER BY
    n.caption DESC
"@

$swisNodeQuery = Get-SwisData -SwisConnection $swis -Query $swqlQuery

foreach ($n in $swisNodeQuery) {
    
    $nodeId = $n.NodeID # NodeID of a node which custom properties you want to change

    # prepare a custom property value
    $customProps = @{
        RDP=$n.Parsed_RDP;
        Department=$n.Parsed_Department;
    }

    # build the node URI
    $uri = "swis://localhost/Orion/Orion.Nodes/NodeID=$($nodeId)/CustomProperties";
    
    # What-If / Dry Run
    Write-Host "Updating $($n.Caption)" -ForegroundColor Cyan
    Write-Host "RDP: $($n.RDP) -> $($customProps.RDP)" -ForegroundColor Green
    Write-Host "Department: $($n.Department) -> $($customProps.Department)`n" -ForegroundColor Green

    # set the custom property
    # Set-SwisObject $swis -Uri $uri -Properties $customProps

}



