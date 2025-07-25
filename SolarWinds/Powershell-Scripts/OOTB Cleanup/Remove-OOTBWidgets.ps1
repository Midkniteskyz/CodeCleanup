# Establish SWIS connection using certificate-based auth
$swisConnection = Connect-Swis -Hostname 'localhost' -Certificate

# Define SWQL query to find common out-of-the-box (OOTB) resources
# These are typically ones you want to remove from summary views
$query = @"
SELECT ResourceID, ResourceName, Uri
FROM Orion.Resources
WHERE ResourceName LIKE 'Getting Started%'
   OR ResourceName LIKE '%thwack%'
   OR ResourceName LIKE '%Custom Object Resource%'
   OR ResourceName LIKE '%What is new%'
   OR ResourceName LIKE '%Multiple Object Chart%'
   OR ResourceName LIKE '%Universal Device Poller Custom Chart%'
   OR ResourceName LIKE '%GettingStarted%'
ORDER BY ResourceName
"@

# Execute the query
$resourcesToRemove = Get-SwisData -SwisConnection $swisConnection -Query $query

# Loop through each resource and attempt to remove it
foreach ($resource in $resourcesToRemove) {
    try {
        Write-Host "Removing resource: $($resource.ResourceName)"
        Remove-SwisObject -SwisConnection $swisConnection -Uri $resource.Uri
    } catch {
        Write-Warning "Failed to remove $($resource.ResourceName): $($_.Exception.Message)"
    }
}
