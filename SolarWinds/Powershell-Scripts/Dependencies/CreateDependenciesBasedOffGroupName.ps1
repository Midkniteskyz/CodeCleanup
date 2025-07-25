# Get all group info
$groups = Get-SwisData $swis @"
SELECT
 MemberPrimaryID,
 FullName,
 MemberEntityType,
 MemberUri
FROM Orion.ContainerMembers
WHERE ContainerID = 134
"@ | ForEach-Object {
    [PSCustomObject]@{
        ContainerID = $_.MemberPrimaryID
        Name        = $_.FullName
        Role        = ($_.FullName -split '_')[-1..0][0]              # In case there is an _ in the site name, reverse the string, split by _, then grab index 0. Same as grabbing the last word (WAN/Core/Access)
        SiteName    = ($_.FullName -replace '_(WAN|Core|Access)$', '').Trim()
        Uri         = $_.MemberUri
        InstanceType= $_.MemberEntityType
    }
}

# Group by site name
$groupedSites = $groups | Group-Object -Property SiteName

foreach ($site in $groupedSites) {
    $siteName = $site.Name
    $siteGroups = $site.Group

    $wan  = $siteGroups | Where-Object { $_.Role -eq 'WAN' }
    $core = $siteGroups | Where-Object { $_.Role -eq 'Core' }
    $access = $siteGroups | Where-Object { $_.Role -eq 'Access' }

    # WAN → Core
    if ($wan -and $core) {
        $props = @{
            Name              = "$siteName - WAN to Core"
            ParentUri         = $wan.Uri
            ParentEntityType  = $wan.InstanceType
            ParentNetObjectID = $wan.ContainerID
            ChildUri          = $core.Uri
            ChildEntityType   = $core.InstanceType
            ChildNetObjectID  = $core.ContainerID
            Description       = "Automated dependency between WAN and Core"
        }

        try {
            New-SwisObject $swis -EntityType 'Orion.Dependencies' -Properties $props
            Write-Host "✅ Created dependency: $($props.Name)" -ForegroundColor Green
        } catch {
            Write-Warning "❌ Failed to create WAN→Core for $siteName — $_"
        }
    }

    # Core → Access
    if ($core -and $access) {
        $props = @{
            Name              = "$siteName - Core to Access"
            ParentUri         = $core.Uri
            ParentEntityType  = $core.InstanceType
            ParentNetObjectID = $core.ContainerID
            ChildUri          = $access.Uri
            ChildEntityType   = $access.InstanceType
            ChildNetObjectID  = $access.ContainerID
            Description       = "Automated dependency between Core and Access"
        }

        try {
            New-SwisObject $swis -EntityType 'Orion.Dependencies' -Properties $props
            Write-Host "✅ Created dependency: $($props.Name)" -ForegroundColor Green
        } catch {
            Write-Warning "❌ Failed to create Core→Access for $siteName — $_"
        }
    }
}
