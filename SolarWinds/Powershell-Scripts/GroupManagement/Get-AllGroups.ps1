# Connect to SWIS
$orionserver = "hco.loop1.ziti"
$username = "L1SENG\RWoolsey"
$password = 'W@shingt0n22!'
$swis = Connect-Swis -Hostname $orionserver -Username $username -Password $password

# Define the base SWQL query
$baseQuery = @"
SELECT

cm.Container.ContainerID as [ParentID]
, cm.Container.name as [Parent Name]
, cm.MemberPrimaryID as [GroupID]
, cm.DisplayName as [Group Name]

FROM Orion.ContainerMembers as cm

Where 
cm.MemberEntityType = 'Orion.Groups' 
AND 
cm.Container.Owner != 'MAPS'

Order By ContainerID, MemberPrimaryID

"@

# Execute the query
$results = Get-SwisData -SwisConnection $swis -Query $baseQuery