# SolarWinds Group Migration Script
# Stops on all errors
$ErrorActionPreference = 'Stop'

# Define servers
$sourceServer = "192.168.21.58"
$destinationServer = "192.168.25.30"
$targetGroupName = "BS Test Group"

# Connect to source and destination SolarWinds environments (using Trusted, or uncomment for credentials)
$sourceCred = Get-Credential -Message "Enter Source SolarWinds Credentials"
# $destCred   = Get-Credential -Message "Enter Destination SolarWinds Credentials"
$swisSource = Connect-Swis -Hostname $sourceServer -Credential $sourceCred
$swisDest   = Connect-Swis -Hostname $destinationServer -Trusted

# Retrieve group info and definitions from source
$groups = Get-SwisData -SwisConnection $swisSource -Query @"
    SELECT ContainerID, Name, Description, Owner, Frequency, StatusCalculator, RollupType,
           IsDeleted, PollingEnabled, LastChanged, UnManageFrom, UnManageUntil, DetailsUrl
    FROM Orion.Container
    WHERE Name = '$targetGroupName'
"@

$groupDefinitions = Get-SwisData -SwisConnection $swisSource -Query @"
    SELECT DefinitionID, ContainerID, Name, Entity, FromClause, Expression, Definition
    FROM Orion.ContainerMemberDefinition
    WHERE ContainerID IN (
        SELECT ContainerID FROM Orion.Container WHERE Name = '$targetGroupName'
    )
"@

# Get URI system ID from destination
$uriBase = Get-SwisData -SwisConnection $swisDest -Query "SELECT SettingValue FROM Orion.WebSettings WHERE SettingName = 'SwisUriSystemIdentifier'"

function Build-MemberXml {
    param (
        [System.Collections.Generic.List[Hashtable]]$members
    )
    $xml = @()
    $xml += "<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>"
    foreach ($m in $members) {
        $xml += "<MemberDefinitionInfo><Name>$($m.Name)</Name><Definition>$($m.Definition)</Definition></MemberDefinitionInfo>"
    }
    $xml += "</ArrayOfMemberDefinitionInfo>"
    return ([xml]($xml -join "`n")).DocumentElement
}

foreach ($group in $groups) {
    $members = New-Object System.Collections.Generic.List[Hashtable]
    $groupName = $group.Name
    Write-Host "`nCreating group '$groupName'" -ForegroundColor Green

    $groupDefs = $groupDefinitions | Where-Object { $_.ContainerID -eq $group.ContainerID }

    foreach ($def in $groupDefs) {
        switch -Wildcard ($def.Definition) {
            "filter:*" {
                $members.Add(@{ Name = $def.Name; Definition = $def.Definition })
                Write-Host "    Adding filter: $($def.Name)" -ForegroundColor Yellow
            }
            "swis:*" {
                switch ($def.Entity) {
                    "Orion.Nodes" {
                        $nodeID = ($def.Expression -split "=")[-1].Trim("'")
                        $nodeInfo = Get-SwisData -SwisConnection $swisSource -Query "SELECT Caption, IPAddress FROM Orion.Nodes WHERE NodeID = '$nodeID'"
                        if ($nodeInfo) {
                            $ip = $nodeInfo.IPAddress
                            $caption = $nodeInfo.Caption
                            $nodeDest = Get-SwisData -SwisConnection $swisDest -Query "SELECT NodeID FROM Orion.Nodes WHERE IPAddress = '$ip'"
                            if ($nodeDest) {
                                $newNodeID = $nodeDest.NodeID
                                $definition = "swis://$uriBase/Orion/Orion.Nodes/NodeID=$newNodeID"
                                $members.Add(@{ Name = "Orion.Nodes Nodes"; Definition = $definition })
                                Write-Host "    Added node '$caption' to group." -ForegroundColor Green
                            } else {
                                Write-Host "    Node '$caption' not found in destination." -ForegroundColor Yellow
                            }
                        } else {
                            Write-Host "    NodeID '$nodeID' not found in source." -ForegroundColor Red
                        }
                    }
                    "Orion.NPM.Interfaces" {
                        $interfaceID = ($def.Expression -split "=")[-1].Trim("'")
                        $ifaceIndex = Get-SwisData -SwisConnection $swisSource -Query "SELECT InterfaceIndex FROM Orion.NPM.Interfaces WHERE InterfaceID = '$interfaceID'"
                        $ifaceNodeIP = Get-SwisData -SwisConnection $swisSource -Query "SELECT i.Node.IP_Address FROM Orion.NPM.Interfaces i WHERE InterfaceID = '$interfaceID'"
                        if ($ifaceIndex -and $ifaceNodeIP) {
                            $destNode = Get-SwisData -SwisConnection $swisDest -Query "SELECT NodeID FROM Orion.Nodes WHERE IPAddress = '$ifaceNodeIP'"
                            $destInterface = Get-SwisData -SwisConnection $swisDest -Query "SELECT InterfaceID, NodeID, FullName FROM Orion.NPM.Interfaces WHERE InterfaceIndex = '$ifaceIndex' AND NodeID = '$($destNode.NodeID)'"
                            if ($destInterface) {
                                $ifaceDef = "swis://$uriBase/Orion/Orion.Nodes/NodeID=$($destInterface.NodeID)/Interfaces/InterfaceID=$($destInterface.InterfaceID)"
                                $ifaceName = "Orion.Nodes.NodeID=$($destInterface.NodeID) Interfaces.InterfaceID=$($destInterface.InterfaceID)"
                                $members.Add(@{ Name = $ifaceName; Definition = $ifaceDef })
                                Write-Host "    Added interface '$($destInterface.FullName)' to group." -ForegroundColor Green
                            } else {
                                Write-Host "    Interface not found in destination." -ForegroundColor Yellow
                            }
                        } else {
                            Write-Host "    Could not resolve interface ID '$interfaceID' in source." -ForegroundColor Red
                        }
                    }
                    "Orion.Groups" {
                        # Subgroup mapping will be done in separate loop
                        continue
                    }
                }
            }
        }
    }

    $groupXml = Build-MemberXml -members $members

    # Create the group on the destination
    $groupId = Invoke-SwisVerb $swisDest "Orion.Container" "CreateContainer" @(
        $group.Name,
        "Core",
        $group.Frequency,
        $group.StatusCalculator,
        $group.Description,
        "true",
        "",  # DetailsUrl
        $groupXml
    ).InnerText

    if ($groupId -and $members.Count -gt 0) {
        Write-Host "Group '$groupName' created with ID $groupId." -ForegroundColor Cyan
    } else {
        Write-Host "Failed to create group '$groupName' or it has no members." -ForegroundColor Red
    }
}

# Handle subgroups (Orion.Groups)
$subGroups = $groupDefinitions | Where-Object { $_.Entity -eq "Orion.Groups" }

foreach ($sub in $subGroups) {
    $parentGroupName = ($groups | Where-Object { $_.ContainerID -eq $sub.ContainerID }).Name
    $subGroupID = ($sub.Definition -split "=")[-1]
    $subGroupName = ($groups | Where-Object { $_.ContainerID -eq $subGroupID }).Name

    $parentGroupID = Get-SwisData -SwisConnection $swisDest -Query "SELECT ContainerID FROM Orion.Container WHERE Name = '$parentGroupName'"
    $targetSubGroupID = Get-SwisData -SwisConnection $swisDest -Query "SELECT ContainerID FROM Orion.Container WHERE Name = '$subGroupName'"

    if ($parentGroupID -and $targetSubGroupID) {
        $members = New-Object System.Collections.Generic.List[Hashtable]
        $members.Add(@{
            Name = "Orion.Groups.ContainerID=$targetSubGroupID"
            Definition = "swis://$uriBase/Orion/Orion.Groups/ContainerID=$targetSubGroupID"
        })
        $xml = Build-MemberXml -members $members

        Write-Host "Linking subgroup '$subGroupName' to parent group '$parentGroupName'" -ForegroundColor Cyan

        Invoke-SwisVerb $swisDest "Orion.Container" "AddDefinitions" @(
            $parentGroupID,
            $xml
        ) | Out-Null
    } else {
        Write-Host "Could not resolve subgroup '$subGroupName' or parent group '$parentGroupName'" -ForegroundColor DarkYellow
    }
}

Write-Host "`nMigration complete. $($groups.Count) group(s) processed." -ForegroundColor Green
