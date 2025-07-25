# Requirements: OrionSDK module, and Sites.csv with a column named 'Site'

# ---- CONFIG ----
$hostname = "spapporikme1"
$csvPath = "C:\Users\jeffrey.funnell\Downloads\nodecp-site.csv"
$parentGroupName = "Sites"
$groupOwner = "Core"  # Must be 'Core'
$refreshRate = 60
$statusRollup = 0  # 0 = warning, 1 = worst, 2 = best
$pollingEnabled = "true"

# ---- CONNECT ----

Import-Module SwisPowerShell

# Create a PSCredential object
$cred = Get-Credential

# Connect to SWIS
$swis = Connect-Swis -Hostname $hostname -Credential $cred


# ---- GET PARENT GROUP URI ----
$parentGroupId = Get-SwisData $swis "SELECT ContainerID FROM Orion.Container WHERE Name = @name" @{ name = $parentGroupName }

if (-not $parentGroupUri) {
    throw "Parent group '$parentGroupName' not found."
}

# ---- IMPORT SITES ----
$sites = Import-Csv -Path $csvPath | Select-Object -ExpandProperty Site

foreach ($siteName in $sites) {
    Write-Host "Processing site: $siteName" -ForegroundColor Cyan

    # Definitions for each subgroup
    $groupDefs = @(
        @{ Role = "WAN"; Name = "${siteName}_WAN"; Definitions = @(
            "filter:/Orion.Nodes[CustomProperties.Site='$siteName' AND CustomProperties.Topology='Hybrid']"
            ) },
            @{ Role = "Core"; Name = "${siteName}_Core"; Definitions = @(
            "filter:/Orion.Nodes[CustomProperties.Site='$siteName' AND CustomProperties.Topology='Vendor Managed']",
            "filter:/Orion.Nodes[CustomProperties.Site='$siteName' AND CustomProperties.Topology='Core']"
        ) },
        @{ Role = "Access"; Name = "${siteName}_Access"; Definitions = @(
            "filter:/Orion.Nodes[CustomProperties.Site='$siteName' AND CustomProperties.Topology='Edge']"
        ) }
    )

    foreach ($group in $groupDefs) {
        $xml = New-Object System.Xml.XmlDocument
        $root = $xml.CreateElement("ArrayOfMemberDefinitionInfo", "http://schemas.solarwinds.com/2008/Orion")
        $xml.AppendChild($root) | Out-Null

        foreach ($definition in $group.Definitions) {
            $member = $xml.CreateElement("MemberDefinitionInfo", $root.NamespaceURI)

            $nameElem = $xml.CreateElement("Name", $root.NamespaceURI)
            $nameElem.InnerText = $group.Name
            $member.AppendChild($nameElem) | Out-Null

            $defElem = $xml.CreateElement("Definition", $root.NamespaceURI)
            $defElem.InnerText = $definition
            $member.AppendChild($defElem) | Out-Null

            $root.AppendChild($member) | Out-Null
        }

        $groupXmlMembers = $root

        # Create the dynamic group
        $childGroupId = (Invoke-SwisVerb $swis "Orion.Container" "CreateContainer" @(
            $group.Name,
            $groupOwner,
            $refreshRate,
            $statusRollup,
            "Auto-created dynamic group for $siteName ($($group.Role))",
            $pollingEnabled,
            $groupXmlMembers
        )).InnerText

        # Get the URI of the created subgroup
        $childGroupUri = Get-SwisData $swis "SELECT Uri FROM Orion.Container WHERE ContainerID = @id" @{ id = $childGroupId }

        # Add subgroup to parent group
        Invoke-SwisVerb $swis "Orion.Container" "AddDefinition" @(
            $parentGroupId,  # Must be an integer ContainerID
            ([xml]"
                <MemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>
                    <Name>$($group.Name)</Name>
                    <Definition>$childGroupUri</Definition>
                </MemberDefinitionInfo>"
            ).DocumentElement
        ) | Out-Null


        Write-Host "  → Created and linked group: $($group.Name)"
    }
}

Write-Host "✅ All groups created and linked under '$parentGroupName'." -ForegroundColor Green
