# ADDING A NEW GROUP MEMBER (Dynamic Query)
#
# Adding up devices in the group.
#
# filter:/Orion.Nodes[CustomProperties.Site='[VPN] SMP Clinic Burnaby' AND CustomProperties.Topology='Core']
# filter:/Orion.Nodes[CustomProperties.Site='[VPN] SMP Clinic Burnaby' AND CustomProperties.Topology='Vendor Managed']


# Get the container IDs
$Containerids = Get-SwisData $swis "
SELECT TOP 1 DefinitionID, ContainerID, Name, Entity, FromClause, Expression, Definition, DisplayName, Description, InstanceType, Uri, InstanceSiteId
FROM Orion.ContainerMemberDefinition
where name like '%_Core'"

foreach ($c in $Containerids) {

    $sanitizedSiteName = $c.Name -replace '&', 'and'

    $dynamicQueryName = "$sanitizedSiteName" + "_Hybrid"

    Invoke-SwisVerb $swis "Orion.Container" "AddDefinition" @(
        # group ID
        $c.DefinitionID,

        # group member to add
        ([xml]"
        <MemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>
        <Name>$dynamicQueryName</Name>
        <Definition>filter:/Orion.Nodes[CustomProperties.Site='$($c.Name)' AND CustomProperties.Topology='Hybrid']</Definition>
        </MemberDefinitionInfo>"
        ).DocumentElement
        ) | Out-Null

    }