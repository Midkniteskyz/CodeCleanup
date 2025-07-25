# Get all Core/Hybrid members with mistaken name/definition
$definitions = Get-SwisData $swis @"
SELECT
  member.DefinitionID,
  member.Name AS MemberName,
  member.Definition AS MemberDefinition
FROM
  Orion.Container AS parent
JOIN
  Orion.ContainerMemberDefinition AS link ON parent.ContainerID = link.ContainerID
JOIN
  Orion.Container AS subgroup ON link.Definition = subgroup.Uri
LEFT JOIN
  Orion.ContainerMemberDefinition AS member ON subgroup.ContainerID = member.ContainerID
WHERE
  parent.Name = 'Sites'
  AND member.Definition LIKE '%_Core'' AND CustomProperties.Topology=''Hybrid'']'
"@

foreach ($d in $definitions) {
    # Fix the name
    $updatedName = $d.MemberName -replace '_Core_Hybrid', '_Hybrid'

    # Fix the filter text
    $updatedFilter = $d.MemberDefinition -replace '_Core', ''

    # Call UpdateDefinition
    Invoke-SwisVerb $swis "Orion.Container" "UpdateDefinition" @(
        $d.DefinitionID,
        ([xml]"
        <MemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>
            <Name>$updatedName</Name>
            <Definition>$updatedFilter</Definition>
        </MemberDefinitionInfo>"
        ).DocumentElement
    ) | Out-Null

    Write-Host "Updated: $($d.MemberName) → $updatedName"
}
