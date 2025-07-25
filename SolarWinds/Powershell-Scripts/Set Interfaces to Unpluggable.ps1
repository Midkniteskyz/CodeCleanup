# Establish SWIS connection using certificate-based authentication
$swisConnection = Connect-Swis -Hostname 'localhost' -Certificate

# Define SWQL query to get all interface URIs where the interface status is NOT:
# 1 = Up, 3 = Warning, 14 = Critical
# Meaning we are targeting interfaces that are Down, Unknown, etc.
$query = @"
SELECT i.Uri
FROM Orion.NPM.Interfaces AS i
WHERE i.Status NOT IN (1, 3, 14)
"@

# Execute the query and retrieve results as a list of URIs
$interfaces = Get-SwisData -SwisConnection $swisConnection -Query $query

# Loop through each interface and set its UnPluggable property to $true
foreach ($uri in $interfaces) {
    try {
        Write-Host "Marking as Unpluggable: $uri"
        Set-SwisObject -SwisConnection $swisConnection -Uri $uri -Properties @{ UnPluggable = $true }
    } catch {
        Write-Warning "Failed to update interface $uri : $($_.Exception.Message)"
    }
}
