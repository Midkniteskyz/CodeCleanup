# Establish SWIS connection using certificate-based auth
$swisConnection = Connect-Swis -Hostname 'localhost' -Certificate

# Define SWQL query to find common out-of-the-box (OOTB) resources
# These are typically ones you want to remove from summary views
$query = @"
SELECT m.MenuName, m.MenuItemID, m.MenuItem.Title, m.Uri
FROM Orion.Web.MenuBars AS m
WHERE m.MenuItem.Title LIKE '%Training%'
   OR m.MenuItem.Title LIKE '%thwack%'
   OR m.MenuItem.Title = 'Custom Summary'
   OR m.MenuItem.Title IS NULL
ORDER BY m.MenuName, m.MenuItem.Title
"@

# Execute the query
$resourcesToRemove = Get-SwisData -SwisConnection $swisConnection -Query $query

# Loop through each resource and attempt to remove it
foreach ($resource in $resourcesToRemove) {
    try {
        Write-Host "Removing resource: $($resource.Title)"
        Remove-SwisObject -SwisConnection $swisConnection -Uri $resource.Uri
    } catch {
        Write-Warning "Failed to remove $($resource.Title): $($_.Exception.Message)"
    }
}