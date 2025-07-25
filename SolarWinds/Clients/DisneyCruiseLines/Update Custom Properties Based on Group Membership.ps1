# ====================================================================
# Script: Update Custom Properties Based on Group Membership
# Description: Updates the 'Access_ROOM_RDP' custom property for nodes
#              based on the first 3 letters of their group's name.
# ====================================================================

# Configuration
$username     = "loop1"
$password     = "30DayPassword!"
$orionserver  = "localhost"
$groupIDs     = @(89, 101, 90, 91, 92, 75, 76, 77, 78, 79, 80, 81, 96, 99, 95, 102, 103, 97, 93, 94, 100, 98, 82, 83, 84, 85, 86, 87, 88)
$dryRun       = $false

# Connect to SolarWinds
try {
    Import-Module SwisPowerShell -ErrorAction Stop
    $swis = Connect-Swis -Hostname $orionserver -Username $username -Password $password
    Write-Host "✅ Connected to SolarWinds" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to connect to SolarWinds: $_"
    exit 1
}

# Format the container ID list for SWQL
$groupIdList = $groupIDs -join "','"

# Query group members
$query = @"
SELECT 
    cmn.ContainerID, 
    c.Name AS GroupName, 
    cmn.NodeId, 
    cmn.Name AS MemberName, 
    cmn.MemberUri 
FROM 
    Orion.ContainerMembersNodes AS cmn 
    JOIN Orion.Container AS c ON c.ContainerID = cmn.ContainerID 
WHERE 
    cmn.ContainerID IN ('$groupIdList')
"@

$groups = Get-SwisData -SwisConnection $swis -Query $query

if (-not $groups) {
    Write-Warning "No group members found for the specified containers."
    exit 0
}

foreach ($g in $groups) {
    try {
        # Get first 3 characters of the group name as room/rdp code
        $rdpCode = $g.GroupName.Substring(0, 3)

        # Prepare the update
        $updateProps = 
        @{
            Access_ROOM_RDP = $rdpCode
        }

        if ($dryRun) {
            Write-Host "[DRY RUN] Would update $($g.MemberName) (NodeID: $($g.NodeId)) with Access_ROOM_RDP & RDP = '$rdpCode'" -ForegroundColor Cyan
        } else {
            Set-SwisObject -SwisConnection $swis -Uri "$($g.MemberUri)/CustomProperties" -Properties $updateProps
            Write-Host "✅ Updated $($g.MemberName) with Access_ROOM_RDP = '$rdpCode'" -ForegroundColor Green
        }
    } catch {
        Write-Warning "⚠️  Failed to update $($g.MemberName): $_"
    }
}

Write-Host "Script completed." -ForegroundColor Yellow
