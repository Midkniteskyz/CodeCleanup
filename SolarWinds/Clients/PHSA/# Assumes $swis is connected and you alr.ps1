# Assumes $swis is connected and you already know the failing group base names

# Define the original group base names (with ampersands etc.)
$failedGroups = @(
    "South Slope Speech & Hearing",
    "Native Youth Health & Wellness Centre",
    "Jim Pattison Outpatient Care & Surgery Center",
    "Irene Thomas Hospice (Residence & Support)",
    "Child & Youth Mental Health(NS Foundry)",
    "Burnaby South Secondary Speech & Hearing",
    "BC Cancer- Patient and Family Counselling & Psychiatry",
    "Abbotsford Regional Hospital & Cancer Centre(BCCA)"
)

# Static group roles and their filter Topology mappings
$roles = @{
    WAN    = @("Hybrid", "Vendor Managed")
    Core   = @("Core")
    Access = @("Edge")
}

# Get parent group ID
$parentGroupId = 134

foreach ($siteBaseName in $failedGroups) {
    $sanitizedSiteName = $siteBaseName -replace '&', 'and'

    foreach ($role in $roles.Keys) {
        $groupName = "${sanitizedSiteName}_$role"
        $queryName = "${siteBaseName}_$role"

        Write-Host "Fixing group: $groupName" -ForegroundColor Cyan

        # Delete existing group if it partially created
        $existingId = Get-SwisData $swis "SELECT ContainerID FROM Orion.Container WHERE Name = @name" @{ name = $groupName }
        if ($existingId) {
            Invoke-SwisVerb $swis "Orion.Container" "DeleteContainer" @($existingId) | Out-Null
            Write-Host "  → Deleted old group: $groupName"
        }

        # Build XML definition with original (ampersand) name in filter
        $xml = New-Object System.Xml.XmlDocument
        $root = $xml.CreateElement("ArrayOfMemberDefinitionInfo", "http://schemas.solarwinds.com/2008/Orion")
        $xml.AppendChild($root) | Out-Null

        foreach ($topology in $roles[$role]) {
            $member = $xml.CreateElement("MemberDefinitionInfo", $root.NamespaceURI)

            $nameElem = $xml.CreateElement("Name", $root.NamespaceURI)
            $nameElem.InnerText = $groupName
            $member.AppendChild($nameElem) | Out-Null

            $defElem = $xml.CreateElement("Definition", $root.NamespaceURI)
            $defElem.InnerText = "filter:/Orion.Nodes[CustomProperties.Site='$siteBaseName' AND CustomProperties.Topology='$topology']"
            $member.AppendChild($defElem) | Out-Null

            $root.AppendChild($member) | Out-Null
        }

        # Create the new group
        $newGroupId = (Invoke-SwisVerb $swis "Orion.Container" "CreateContainer" @(
            $groupName,
            "Core",
            60,
            0,
            "Recreated group for $siteBaseName ($role)",
            "true",
            $xml.DocumentElement
        )).InnerText

        # Add it back to parent
        $childUri = Get-SwisData $swis "SELECT Uri FROM Orion.Container WHERE ContainerID = @id" @{ id = $newGroupId }

        Invoke-SwisVerb $swis "Orion.Container" "AddDefinition" @(
            $parentGroupId,
            ([xml]"
                <MemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>
                    <Name>$groupName</Name>
                    <Definition>$childUri</Definition>
                </MemberDefinitionInfo>"
            ).DocumentElement
        ) | Out-Null

        Write-Host "  → Recreated and linked group: $groupName" -ForegroundColor Green
    }
}
