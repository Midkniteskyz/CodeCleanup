# Login Info
$ships = @{
    Wish = '10.60.15.200'
    Lighthouse = '10.217.161.206'
    Castaway = '10.61.131.17'
    Dream = '10.56.15.206'
    Magic = '10.58.15.206'
    Wonder = '10.59.15.206'
    Fantasy = '10.57.15.206'
}

$user = 'loop1'
$password = '30DayPassword!'

# Results Table
$results = @()
$failedresults = @()

# Prompt for Machine type
$MachineType = Read-Host "What machine type should be searched for?"

# Loop through each ship in the hashtable
foreach ($ship in $ships.GetEnumerator()) {
    $hostname = $ship.Value
    $shipName = $ship.Key
    
    Write-Output "Connecting to $shipName at $hostname"
    
    try {
        # Attempt to connect to SWIS
        $swis = Connect-Swis -Hostname $hostname -UserName $user -Password $password -ErrorAction Stop
        Write-Output "Successfully connected to $shipName"

        # Run the Get-SwisData command and store results
        $query = 'SELECT Caption, IPAddress, MachineType, IOSVersion FROM Orion.Nodes WHERE MachineType LIKE @m'
        $parameters = @{ m = "%$MachineType%" }

        $data = Get-SwisData -SwisConnection $swis -Query $query -Parameters $parameters

        # Loop through the returned data and splat the values into the result
        foreach ($row in $data) {
            $results += [pscustomobject]@{
                Ship    = $shipName
                Caption  = $row.Caption
                IPAddress = $row.IPAddress
                MachineType = $row.MachineType
                IOSVersion = $row.IOSVersion

            }
        }

    } catch {
        # Handle connection errors
        Write-Error "Failed to connect to $shipName at $hostname. Error: $_"
        
        # Store the failure result
        $failedresults += [pscustomobject]@{
            Ship      = $shipName
            Hostname  = $hostname
            Data      = "Connection Failed"
        }
    }
}

# Output the results in a readable format
# $results | Format-Table -AutoSize

# Out Grid View
#$results | OGV 

# Output to a CSV
$guid = [guid]::NewGuid()
$results | Out-File -FilePath "D:\SolarWinds-FIles\Exports\Get-IOSVersions\Results_$guid.csv" -Verbose


