# Remove-SwisObject $swis -Uri 'swis://spappnpm001.vch.ca/Orion/Orion.Dependencies/DependencyId=7'

# Query all the groups and necessary information to start building objects
$GroupsSWQLQuery = Get-SwisData $swis "
            SELECT ContainerID, Name, InstanceType, Uri
            FROM Orion.Groups
            "
# Find group names that match up to the underscore, this is the site. Save it as $SiteName
# Example data. 

ContainerID  : 251
Name         : Abbotsford Health Protection Services_WAN
InstanceType : Orion.Groups
Uri          : swis://spappnpm001.vch.ca/Orion/Orion.Groups/ContainerID=251

ContainerID  : 252
Name         : Abbotsford Health Protection Services_Core
InstanceType : Orion.Groups
Uri          : swis://spappnpm001.vch.ca/Orion/Orion.Groups/ContainerID=252

ContainerID  : 253
Name         : Abbotsford Health Protection Services_Access
InstanceType : Orion.Groups
Uri          : swis://spappnpm001.vch.ca/Orion/Orion.Groups/ContainerID=253

# of the matching names, if theres one ending with _WAN and one ending with _core, create a dependency with the wan as the parent and the core as the child

# The denpendencies object require certain properties. 
# Dependency properties

$dependencyProperties = @{
    Name      = "$SiteName - WAN to Core"
    ParentUri = 'swis://spappnpm001.vch.ca/Orion/Orion.Groups/ContainerID=164'
    ParentEntityType = Orion.Groups
    ParentNetObjectID = 164
    ChildUri  = 'swis://spappnpm001.vch.ca/Orion/Orion.Groups/ContainerID=165'
    ChildEntityType = Orion.Groups
    ChildNetObjectID = 165
    Description = "Test Dependency Created"
}

New-SwisObject $swis -EntityType 'Orion.Dependencies' -Properties $DependencyProperties





SELECT

 MemberPrimaryID,
 FullName,
 MemberEntityType,
 MemberUri

FROM Orion.ContainerMembers
WHERE ContainerID = 134



($groups[105].FullName)-join ($_.ToCharArray() | ForEach-Object {$_})[-1..-($original.Length)]




$original = "SolarWinds"
$reversed = -join ($original.ToCharArray() | ForEach-Object {$_})[-1..-($original.Length)]
