# Open a connection to SWIS
$swis = Connect-Swis -Hostname myorionserver.mydomain -Username mickeymouse -Password minnie

# Get a list of Uris for the interfaces you want to change
$uris = Get-SwisData $swis "SELECT Uri FROM Orion.NPM.Interfaces WHERE my-filter-expression"

# Set the "Unpluggable" property to true on those interfaces
$uris | Set-SwisObject $swis -properties @{Unpluggable=$true}