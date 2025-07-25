# Connect to SolarWinds SWIS
function Connect-SolarWinds {
    param (
        [string]$hostname,
        [string]$user,
        [string]$password
    )

    $swisParams = @{
        Hostname = $hostname
        UserName = $user
        Password = $password
        ErrorAction = 'Stop'
    }
    
    try {
        return Connect-Swis @swisParams
    }
    catch {
        Write-Error "Failed to connect to SWIS: $_"
        return $null
    }
}

# Retrieve custom property fields from SolarWinds
function Get-CustomPropertyFields {
    param (
        [object]$swis
    )

    $query = "SELECT Field FROM Orion.CustomProperty WHERE Table = 'NodesCustomProperties'"
    return Get-SwisData $swis $query
}

# Build SWQL query to retrieve node properties
function Build-NodeQuery {
    param (
        [array]$customProperties
    )

    # Join custom property fields into a formatted string
    $CPFieldsFormatted = $CPFields | ForEach-Object { "n.CustomProperties.$_" }
    $CPFieldsFormatted = $CPFieldsFormatted -join ",`n"

    # Build the SWQL query
    return @"
    SELECT
        n.Caption,
        n.Vendor,
        n.MachineType,
        SUBSTRING(n.IPAddress, 1, CHARINDEX('.', n.IPAddress) - 1) AS [Octet1],
        SUBSTRING(n.IPAddress, CHARINDEX('.', n.IPAddress) + 1, CHARINDEX('.', n.IPAddress, CHARINDEX('.', n.IPAddress) + 1) - CHARINDEX('.', n.IPAddress) - 1) AS [Octet2],
        SUBSTRING(n.IPAddress, CHARINDEX('.', n.IPAddress, CHARINDEX('.', n.IPAddress) + 1) + 1, CHARINDEX('.', n.IPAddress, CHARINDEX('.', n.IPAddress, CHARINDEX('.', n.IPAddress) + 1) + 1) - CHARINDEX('.', n.IPAddress, CHARINDEX('.', n.IPAddress) + 1) - 1) AS [Octet3],
        SUBSTRING(n.IPAddress, CHARINDEX('.', n.IPAddress, CHARINDEX('.', n.IPAddress, CHARINDEX('.', n.IPAddress) + 1) + 1) + 1, LENGTH(n.IPAddress)) AS [Octet4],
        $($CPFieldsFormatted),
        n.CustomProperties.URI
    FROM Orion.Nodes AS n
"@
}

# Retrieve current node data from SolarWinds
function Get-NodeData {
    param (
        [object]$swis,
        [string]$query
    )

    return Get-SwisData $swis $query
}

# Update environment based on Octet2 value
function Update-Environment {
    param (
        [PSCustomObject]$node
    )

    # Environment map
    $environmentMap = @{
        '56'  = 'Dream'
        '57'  = 'Fantasy'
        '58'  = 'Magic'
        '59'  = 'Wonder'
        '60'  = 'Castaway'
        '61'  = 'Castaway'
        '217' = 'LightHouse Point'
    }

    $currentEnvironment = $environmentMap.($node.Octet2)

    if ([string]::IsNullOrEmpty($node.Environment) -or $node.Environment -ne $currentEnvironment) {
        Write-Verbose "[UPDATE] $($node.Caption) : Environment updated to '$currentEnvironment' based on IP Octet 2: '$($node.Octet2)'." 
        $node.Environment = $currentEnvironment
    }
    else {
        Write-Verbose "[NO CHANGE] $($node.Caption) : Environment is already set to '$($node.Environment)'." 
    }

    return $node.Environment
}


# Update Device_Type if Caption or MachineType contains a matching keyword
function Update-DeviceType {
    param (
        [PSCustomObject]$node
    )

    # Define a map of keywords and their corresponding device types
    $DeviceTypeMap = @{
        MachineType = @{
            # Checking Machine Type
            'Switch'                = 'Switch'
            'Wireless Controller'   = 'Wireless Controller'
            'ISR'                   = 'Router'
            'DRAC'                  = "Remote Management Interface"
            'Nexus'                 = "Data Center Switch"
            'PA-5220'               = "Firewall"
            'Panorama'              = "Firewall"
            'Veritiv'               = "UPS"
            'Emerson'               = "UPS"
            'Liebert'               = "UPS"
            "VMware ESX Server"     = "Hypervisor"
            "VMware vCenter Server" = "Virtualization Management Server"
            'Windows'               = "Server"
        }

        Caption = @{
            # Checking the Caption
            'tc' = 'Time Clock'
            '-sw'    = 'Switch'
            'radionode'    = 'RFID Reader'
            'brightsign'    = 'Digital Sinage'
            'solar' = 'Server'
            'pos' = 'Point of Sale'
        }
    }

    $deviceTypeUpdated = $false  # Track if an update has been made


    # Iterate through the DeviceTypeMap to check if any key is present in the Caption or MachineType
    foreach ($table in $DeviceTypeMap.Keys) {

        Write-Verbose "Checking Device_Type Table: $table"

        foreach ($key in $DeviceTypeMap.$table.Keys) {
            Write-Verbose "Checking key: $key"

            if ($node.MachineType -match $key) {
                $newDeviceType = $DeviceTypeMap.$table[$key]
                # Write-Host "[UPDATE] $($node.Caption) : Device_Type updated to '$newDeviceType' based on keyword '$key' found in $table." -ForegroundColor Cyan
                $node.Device_Type = $newDeviceType
                $deviceTypeUpdated = $true
            }elseif ($node.Caption -match $key) {
                $newDeviceType = $DeviceTypeMap.$table[$key]
                # Write-Host "[UPDATE] $($node.Caption) : Device_Type updated to '$newDeviceType' based on keyword '$key' found in $table." -ForegroundColor Cyan
                $node.Device_Type = $newDeviceType
                $deviceTypeUpdated = $true
            }
        }

        
    }

    # If no update was made, indicate that no changes were necessary
    if (-not $deviceTypeUpdated) {
        Write-Verbose "[NO CHANGE] $($node.Caption) : Device_Type is already set to '$($node.Device_Type)'." 
    }

    return $node.Device_Type
}


# Update Device_Function based off Caption contents
function Update-DeviceFunction {
    param (
        [PSCustomObject]$node
    )

    # Define a map of keywords and their corresponding device functions
    $DeviceFunctionMap = @{
        'brightsign' = 'Brightsign'
        'ex' = 'Exchange'
        'ora' = 'Oracle'
        'sql' = 'SQL'
    }

    $deviceFunctionUpdated = $false  # Track if an update has been made

    # Iterate through the DeviceTypeMap to check if any key is present in the Caption or MachineType
    foreach ($key in $DeviceFunctionMap.Keys) {

        Write-Verbose "Checking Device_Type Table: $table"

     
            Write-Verbose "Checking key: $key"

            if ($node.Caption -match $key) {
                $newDeviceFunction = $DeviceFunctionMap[$key]
                # Write-Host "[UPDATE] $($node.Caption) : Device_Function updated to '$newDeviceFunction' based on keyword '$key'" -ForegroundColor Cyan
                $node.Device_Function = $newDeviceFunction
                $deviceFunctionUpdated = $true
            }
        
    }

    # If no update was made, indicate that no changes were necessary
    if (-not $deviceFunctionUpdated) {
        Write-Verbose "[NO CHANGE] $($node.Caption) : Device_Function is already set to '$($node.Device_Function)' or no matching keyword found."
    }

    return $node.Device_Function
}

# Build the list of nodes to update based on the retrieved node data
function Build-NodeUpdateList {
    param (
        [array]$nodes
    )

    $updateList = @()

    foreach ($n in $nodes) {
        # Store previous values for comparison
        $oldEnvironment = $n.Environment
        $oldDeviceType = $n.Device_Type
        $oldDeviceFunction = $n.Device_Function

        # Update the environment, device type, and device function
        $newEnvironment = Update-Environment -node $n 
        $newDeviceType = Update-DeviceType -node $n
        $newDeviceFunction = Update-DeviceFunction -node $n

        # Build properties hashtable and track changes
        $properties = @{}

        # Check if Environment has changed
        if ($newEnvironment -ne $oldEnvironment) {
            Write-Host "[CHANGE] $($n.Caption) : Environment changed from '$oldEnvironment' to '$newEnvironment'" -ForegroundColor Yellow
            $properties['Environment'] = $newEnvironment
        }

        # Check if Device_Type has changed
        if ($newDeviceType -ne $oldDeviceType) {
            Write-Host "[CHANGE] $($n.Caption) : Device_Type changed from '$oldDeviceType' to '$newDeviceType'" -ForegroundColor Yellow
            $properties['Device_Type'] = $newDeviceType
        }

        # Check if Device_Function has changed
        if ($newDeviceFunction -ne $oldDeviceFunction) {
            Write-Host "[CHANGE] $($n.Caption) : Device_Function changed from '$oldDeviceFunction' to '$newDeviceFunction'" -ForegroundColor Yellow
            $properties['Device_Function'] = $newDeviceFunction
        }

        # Only add to update list if there are changes
        if ($properties.Count -gt 0) {
            # Add node to update list
            $updateList += [PSCustomObject]@{
                Uri        = $n.Uri
                Node       = $n.Caption
                Properties = $properties
            }
        }
        else {
            Write-Host "[NO CHANGE] $($n.Caption) : No updates needed for this node." -ForegroundColor Gray
        }
    }

    return $updateList
}


# Perform updates using Set-SwisObject
function Update-NodesInSolarWinds {
    param (
        [object]$swis,
        [array]$nodeUpdates
    )

    foreach ($update in $nodeUpdates) {
        Write-Host "Updating node with URI: $($update.Uri)"
        Write-Host "Properties: $($update.Properties | Out-String)"
        # Uncomment to apply actual updates
        Set-SwisObject -SwisConnection $swis -Uri $update.Uri -Properties $update.Properties
    }
}

# Main function to run the script for a specific server
function Main {
    param (
        [string]$hostname
    )

    # Connection parameters
    $user = 'loop1'
    $password = '30DayPassword!'

    Write-Host "Connecting to SolarWinds server: $hostname" -ForegroundColor Yellow

    # Connect to SWIS
    $swis = Connect-SolarWinds -hostname $hostname -user $user -password $password
    if (-not $swis) {
        Write-Error "Unable to connect to SolarWinds on $hostname"
        return
    }

    # Retrieve custom properties
    $customProperties = Get-CustomPropertyFields -swis $swis

    # Build and execute the node query
    $query = Build-NodeQuery -customProperties $customProperties
    $nodeData = Get-NodeData -swis $swis -query $query

    # Build the list of nodes to update
    $nodeUpdates = Build-NodeUpdateList -nodes $nodeData

    # Perform the updates
    Update-NodesInSolarWinds -swis $swis -nodeUpdates $nodeUpdates
}

# List of servers to process
$servers = @(
    'localhost',
    #'10.217.161.203', # LightHouse
    '10.60.15.200', # Wish
    '10.59.15.206' # Wonder
    '10.57.15.206', # Fantasy
    '10.56.15.206', # Dream
    '10.58.15.206' # Magic
    '10.61.131.17' # Castaway
)

# Loop through each server and run the Main function
foreach ($server in $servers) {
    Main -hostname $server
}
