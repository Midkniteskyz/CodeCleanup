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

# Loop through each ship in the hashtable
foreach ($ship in $ships.GetEnumerator()) {
    $hostname = $ship.Value
    $shipName = $ship.Key
    
    Write-Output "Connecting to $shipName at $hostname"
    
    try {
        # Attempt to connect to SWIS
        $swisParams = @{
            Hostname = $hostname
            UserName = $user
            Password = $password
            ErrorAction = 'Stop'
        }
        $swis = Connect-Swis @swisParams
        Write-Output "Successfully connected to $shipName"

        # Prepare splatted parameters for Get-SwisData
        $queryParams = @{
            SwisConnection = $swis
            Query = 'SELECT n.Caption, n.IPAddress, n.MachineType, n.IOSVersion, n.HardwareHealthInfos.ServiceTag FROM Orion.Nodes as n WHERE MachineType LIKE  @m'
            Parameters = @{ m = "%$MachineType%" }
        }

        # Run the Get-SwisData command and store results
        $data = Get-SwisData @queryParams

        # Dynamically generate the object properties from the data columns
        foreach ($row in $data) {
            $result = [ordered]@{ Ship = $shipName }

            # Dynamically add all properties from the row data
            foreach ($property in $row.PSObject.Properties) {
                $result[$property.Name] = $property.Value
            }

            # Add to results
            $results += [pscustomobject]$result
        }

    } catch {
        # Handle connection errors
        Write-Error "Failed to connect to $shipName at $hostname. Error: $_"
    }
}

# Output the results in a readable format
#$results | Format-Table -AutoSize | 

# Out Grid View
#$results | OGV 

# Output to a CSV
$guid = [guid]::NewGuid()
$results | export-csv "D:\SolarWinds-FIles\Exports\Get-IOSVersions\Results_$guid.csv" -notypeinformation -Verbose
