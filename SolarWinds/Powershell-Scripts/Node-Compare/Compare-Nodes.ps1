# Core Nodes Query
$CoreNodesQuery = @'
SELECT 
  --NodeID, 
  Caption, 
  SysName, 
  IPAddress, 
  DNS, 
  ObjectSubType, 
  SNMPVersion, 
  Community, 
  RWCommunity,
  Vendor, 
  MachineType, 
  Status, 
  n.engine.displayname,
  EngineID, 
  External 
FROM 
  Orion.Nodes as n
ORDER BY Vendor, MachineType, SysName, IPAddress
'@

# SolarWinds environments
$PreviousSolarWindsEnvironment = 'OldSolarWinds'
$NewSolarWindsEnvironment = 'NewSolarWinds'

# credentials
$Username = 'username'
$Password = 'password'

# Connect to each SolarWinds environment
$swisOldEnv = Connect-Swis -Hostname $PreviousSolarWindsEnvironment -Username $Username -Password $Password
$swisNewEnv = Connect-Swis -Hostname $NewSolarWindsEnvironment -Username $Username -Password $Password

# Get node data
$OldCoreNodes = Get-SwisData $swisOldEnv $CoreNodesQuery
$NewCoreNodes = Get-SwisData $swisNewEnv $CoreNodesQuery

# Add environment metadata
$OldCoreNodes | ForEach-Object { $_ | Add-Member -NotePropertyName Environment -NotePropertyValue $PreviousSolarWindsEnvironment }
$NewCoreNodes | ForEach-Object { $_ | Add-Member -NotePropertyName Environment -NotePropertyValue $NewSolarWindsEnvironment }

# Compare by IPAddress
$uniqueOld = $OldCoreNodes | Where-Object { $_.IPAddress -notin $NewCoreNodes.IPAddress }
$uniqueNew = $NewCoreNodes | Where-Object { $_.IPAddress -notin $OldCoreNodes.IPAddress }

# Combine results
$allUnique = $uniqueOld + $uniqueNew

# Output to GridView
$allUnique | Sort-Object Environment, Vendor, MachineType, Caption, IPAddress | Out-GridView -Title "Nodes Unique to Each Environment (by IP)"

