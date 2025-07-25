<#
.SYNOPSIS
    Migrates SolarWinds groups and their members from source to destination server.

.DESCRIPTION
    This script migrates groups, their definitions, and members between SolarWinds servers.
    Supports nodes, interfaces, and subgroups. Includes comprehensive error handling and logging.

.PARAMETER SourceServer
    IP address or hostname of the source SolarWinds server

.PARAMETER DestinationServer
    IP address or hostname of the destination SolarWinds server

.PARAMETER GroupFilter
    Optional filter for specific group names. Use * wildcards. Default migrates all groups.

.PARAMETER LogPath
    Path for log file. Default: ./SolarWinds_Migration_Log.txt

.PARAMETER UseTrustedConnection
    Use trusted authentication instead of prompting for credentials

.EXAMPLE
    .\Migrate-SolarWindsGroups.ps1 -SourceServer "192.168.21.58" -DestinationServer "192.168.25.30"
    
.EXAMPLE
    .\Migrate-SolarWindsGroups.ps1 -SourceServer "sw-prod" -DestinationServer "sw-test" -GroupFilter "*Test*" -UseTrustedConnection
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceServer,
    
    [Parameter(Mandatory = $true)]
    [string]$DestinationServer,
    
    [string]$GroupFilter = "*",
    
    [string]$LogPath = ".\SolarWinds_Migration_Log.txt",
    
    [switch]$UseTrustedConnection
)

# Enhanced error handling
$ErrorActionPreference = 'Stop'
$WarningPreference = 'Continue'

# Initialize logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Output to console with colors
    switch ($Level) {
        'Success' { Write-Host $logMessage -ForegroundColor Green }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        default { Write-Host $logMessage -ForegroundColor White }
    }
    
    # Output to log file
    Add-Content -Path $LogPath -Value $logMessage
}

try {
    Write-Log "Starting SolarWinds group migration" -Level Info
    Write-Log "Source: $SourceServer | Destination: $DestinationServer" -Level Info
    
    # Load the SolarWinds Information Service module (OrionSDK PowerShell module)
    Import-Module SwisPowerShell -ErrorAction Stop
    
    # Establish connections
    Write-Log "Establishing server connections..." -Level Info
    
    if ($UseTrustedConnection) {
        $swisSource = Connect-Swis -Hostname $SourceServer -Trusted
        $swisDest = Connect-Swis -Hostname $DestinationServer -Trusted
        Write-Log "Connected using Trusted authentication" -Level Success
    } else {
        $sourceCred = Get-Credential -Message "Enter credentials for Source Server ($SourceServer)"
        $destCred = Get-Credential -Message "Enter credentials for Destination Server ($DestinationServer)"
        
        $swisSource = Connect-Swis -Hostname $SourceServer -Credential $sourceCred
        $swisDest = Connect-Swis -Hostname $DestinationServer -Credential $destCred
        Write-Log "Connected using provided credentials" -Level Success
    }
    
    # Get destination server URL for SWIS URIs
    $destinationUrl = Get-SwisData -SwisConnection $swisDest -Query "SELECT SettingValue FROM Orion.WebSettings WHERE SettingName='SwisUriSystemIdentifier'"
    Write-Log "Destination URL: $destinationUrl" -Level Info
    
    # Build group query with optional filter
    $groupQuery = "SELECT ContainerID, Name, Description, Owner, Frequency, StatusCalculator, RollupType, IsDeleted, PollingEnabled, LastChanged, UnManageFrom, UnManageUntil, DetailsUrl FROM Orion.Container"
    if ($GroupFilter -ne "*") {
        $groupQuery += " WHERE Name LIKE '$GroupFilter'"
    }
    
    # Get groups and their definitions
    Write-Log "Retrieving groups from source server..." -Level Info
    $groups = Get-SwisData -SwisConnection $swisSource -Query $groupQuery
    
    if (!$groups) {
        Write-Log "No groups found matching filter: $GroupFilter" -Level Warning
        return
    }
    
    Write-Log "Found $($groups.Count) group(s) to migrate" -Level Info
    
    # Get all group definitions in one query for efficiency
    $containerIds = ($groups | ForEach-Object { "'$($_.ContainerID)'" }) -join ","
    $definitionsQuery = "SELECT DefinitionID, ContainerID, Name, Entity, FromClause, Expression, Definition FROM Orion.ContainerMemberDefinition WHERE ContainerID IN ($containerIds)"
    $groupDefinitions = Get-SwisData -SwisConnection $swisSource -Query $definitionsQuery
    
    # Process each group
    $processedGroups = @{}
    
    foreach ($group in $groups) {
        try {
            $groupName = $group.Name
            Write-Log "Processing group: $groupName" -Level Info
            
            # Check if group already exists on destination
            $existingGroup = Get-SwisData -SwisConnection $swisDest -Query "SELECT ContainerID FROM Orion.Container WHERE Name = '$groupName'" -ErrorAction SilentlyContinue
            if ($existingGroup) {
                Write-Log "Group '$groupName' already exists on destination server. Skipping." -Level Warning
                continue
            }
            
            $members = @()
            $groupDefsForThisGroup = $groupDefinitions | Where-Object { $_.ContainerID -eq $group.ContainerID }
            
            # Process group member definitions
            if ($groupDefsForThisGroup) {
                foreach ($definition in $groupDefsForThisGroup) {
                    try {
                        $members += Get-MigratedMember -Definition $definition -SwisSource $swisSource -SwisDest $swisDest -DestinationUrl $destinationUrl
                    }
                    catch {
                        Write-Log "Failed to process definition for group '$groupName': $($_.Exception.Message)" -Level Warning
                    }
                }
            }
            
            # Create the group
            $newGroupId = New-SolarWindsGroup -Group $group -Members $members -SwisConnection $swisDest
            
            if ($newGroupId) {
                $processedGroups[$group.ContainerID] = @{
                    Name = $groupName
                    NewId = $newGroupId
                    OriginalId = $group.ContainerID
                }
                Write-Log "Successfully created group: $groupName (ID: $newGroupId)" -Level Success
            }
        }
        catch {
            Write-Log "Failed to process group '$($group.Name)': $($_.Exception.Message)" -Level Error
        }
    }
    
    # Process subgroups (groups within groups) in a second pass
    Write-Log "Processing subgroup relationships..." -Level Info
    $subGroupDefs = $groupDefinitions | Where-Object { $_.Entity -eq "Orion.Groups" }
    
    foreach ($subGroupDef in $subGroupDefs) {
        try {
            Add-SubgroupToParent -SubGroupDefinition $subGroupDef -ProcessedGroups $processedGroups -SwisDest $swisDest -DestinationUrl $destinationUrl
        }
        catch {
            Write-Log "Failed to process subgroup relationship: $($_.Exception.Message)" -Level Warning
        }
    }
    
    Write-Log "Migration completed successfully. Processed $($processedGroups.Count) groups." -Level Success
}
catch {
    Write-Log "Critical error during migration: $($_.Exception.Message)" -Level Error
    Write-Log "Stack trace: $($_.Exception.StackTrace)" -Level Error
    throw
}
finally {
    # Clean up connections
    if ($swisSource) { Disconnect-Swis -SwisConnection $swisSource -ErrorAction SilentlyContinue }
    if ($swisDest) { Disconnect-Swis -SwisConnection $swisDest -ErrorAction SilentlyContinue }
    Write-Log "Connections closed" -Level Info
}

# Helper function to migrate individual group members
function Get-MigratedMember {
    param(
        $Definition,
        $SwisSource,
        $SwisDest,
        $DestinationUrl
    )
    
    $members = @()
    
    switch -Wildcard ($Definition.Definition) {
        "filter:*" {
            # Filter-based definitions can be copied directly
            $members += @{
                Name = $Definition.Name
                Definition = $Definition.Definition
            }
            Write-Log "    Adding filter definition: $($Definition.Definition)" -Level Info
        }
        
        "swis:*" {
            switch ($Definition.Entity) {
                "Orion.Nodes" {
                    $members += Get-MigratedNode -Definition $Definition -SwisSource $SwisSource -SwisDest $SwisDest -DestinationUrl $DestinationUrl
                }
                
                "Orion.NPM.Interfaces" {
                    $members += Get-MigratedInterface -Definition $Definition -SwisSource $SwisSource -SwisDest $SwisDest -DestinationUrl $DestinationUrl
                }
                
                default {
                    Write-Log "    Unsupported entity type: $($Definition.Entity)" -Level Warning
                }
            }
        }
        
        default {
            Write-Log "    Unsupported definition type: $($Definition.Definition)" -Level Warning
        }
    }
    
    return $members
}

# Helper function to migrate node members
function Get-MigratedNode {
    param($Definition, $SwisSource, $SwisDest, $DestinationUrl)
    
    # Extract NodeID from expression
    $nodeId = if ($Definition.Expression -like "Nodes.Uri=*") {
        ($Definition.Expression.Split("=")[2]).Replace("'", "")
    } else {
        $Definition.Expression.Split("=")[1]
    }
    
    # Get source node information
    $nodeInfo = Get-SwisData -SwisSource $SwisSource -Query "SELECT Caption, IPAddress FROM Orion.Nodes WHERE NodeID = '$nodeId'" -ErrorAction SilentlyContinue
    
    if (!$nodeInfo) {
        Write-Log "    Source node with ID $nodeId not found" -Level Warning
        return @()
    }
    
    # Find corresponding node on destination by IP address
    $destNode = Get-SwisData -SwisConnection $SwisDest -Query "SELECT NodeID, Caption FROM Orion.Nodes WHERE IPAddress = '$($nodeInfo.IPAddress)'" -ErrorAction SilentlyContinue
    
    if ($destNode) {
        $definition = "swis://$DestinationUrl/Orion/Orion.Nodes/NodeID=$($destNode.NodeID)"
        Write-Log "    Adding node: $($nodeInfo.Caption) ($($nodeInfo.IPAddress))" -Level Success
        
        return @{
            Name = "Orion.Nodes Nodes"
            Definition = $definition
        }
    } else {
        Write-Log "    Node $($nodeInfo.Caption) ($($nodeInfo.IPAddress)) not found on destination" -Level Warning
        return @()
    }
}

# Helper function to migrate interface members
function Get-MigratedInterface {
    param($Definition, $SwisSource, $SwisDest, $DestinationUrl)
    
    # Extract InterfaceID from expression
    $interfaceId = ($Definition.Expression.Split("=")[3]).Replace("'", "")
    
    # Get source interface information
    $sourceInterface = Get-SwisData -SwisConnection $SwisSource -Query @"
        SELECT i.InterfaceIndex, i.Node.IPAddress, i.FullName 
        FROM Orion.NPM.Interfaces i 
        WHERE i.InterfaceID = '$interfaceId'
"@ -ErrorAction SilentlyContinue
    
    if (!$sourceInterface) {
        Write-Log "    Source interface with ID $interfaceId not found" -Level Warning
        return @()
    }
    
    # Find destination node by IP
    $destNodeId = Get-SwisData -SwisConnection $SwisDest -Query "SELECT NodeID FROM Orion.Nodes WHERE IPAddress = '$($sourceInterface.IPAddress)'" -ErrorAction SilentlyContinue
    
    if ($destNodeId) {
        # Find matching interface by index and node
        $destInterface = Get-SwisData -SwisConnection $SwisDest -Query @"
            SELECT InterfaceID, FullName 
            FROM Orion.NPM.Interfaces 
            WHERE InterfaceIndex = '$($sourceInterface.InterfaceIndex)' 
            AND NodeID = '$destNodeId'
"@ -ErrorAction SilentlyContinue
        
        if ($destInterface) {
            $definition = "swis://$DestinationUrl/Orion/Orion.Nodes/NodeID=$destNodeId/Interfaces/InterfaceID=$($destInterface.InterfaceID)"
            $name = "Orion.Nodes.NodeID=$destNodeId Interfaces.InterfaceID=$($destInterface.InterfaceID)"
            
            Write-Log "    Adding interface: $($destInterface.FullName)" -Level Success
            
            return @{
                Name = $name
                Definition = $definition
            }
        } else {
            Write-Log "    Interface $($sourceInterface.FullName) not found on destination node" -Level Warning
        }
    } else {
        Write-Log "    Destination node with IP $($sourceInterface.IPAddress) not found" -Level Warning
    }
    
    return @()
}

# Helper function to create SolarWinds group
function New-SolarWindsGroup {
    param($Group, $Members, $SwisConnection)
    
    # Prepare member definitions XML
    $memberXml = if ($Members.Count -gt 0) {
        $memberDefinitions = $Members | ForEach-Object {
            "<MemberDefinitionInfo><Name>$($_.Name)</Name><Definition>$($_.Definition)</Definition></MemberDefinitionInfo>"
        }
        
        ([xml]@(
            "<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>",
            [string]($memberDefinitions -join ""),
            "</ArrayOfMemberDefinitionInfo>"
        )).DocumentElement
    } else {
        ([xml]"<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'></ArrayOfMemberDefinitionInfo>").DocumentElement
    }
    
    # Create the group
    $groupId = (Invoke-SwisVerb $SwisConnection "Orion.Container" "CreateContainer" @(
        $Group.Name,                    # Group name
        "Core",                         # Owner (must be 'Core')
        $Group.Frequency,               # Refresh frequency
        $Group.StatusCalculator,        # Status rollup mode
        $Group.Description,             # Description
        "true",                         # Polling enabled
        "",                             # Reserved parameter
        $memberXml                      # Group members
    )).InnerText
    
    return $groupId
}

# Helper function to add subgroups to parent groups
function Add-SubgroupToParent {
    param($SubGroupDefinition, $ProcessedGroups, $SwisDest, $DestinationUrl)
    
    $oldSubGroupId = $SubGroupDefinition.Definition.Split("=")[1]
    
    # Find the parent and child groups in our processed list
    $parentGroup = $ProcessedGroups[$SubGroupDefinition.ContainerID]
    $childGroup = $ProcessedGroups[$oldSubGroupId]
    
    if ($parentGroup -and $childGroup) {
        $definition = "swis://$DestinationUrl/Orion/Orion.Groups/ContainerID=$($childGroup.NewId)"
        $name = "Orion.Groups.ContainerID=$($childGroup.NewId)"
        
        $memberXml = ([xml]@(
            "<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>",
            "<MemberDefinitionInfo><Name>$name</Name><Definition>$definition</Definition></MemberDefinitionInfo>",
            "</ArrayOfMemberDefinitionInfo>"
        )).DocumentElement
        
        Invoke-SwisVerb $SwisDest "Orion.Container" "AddDefinitions" @(
            $parentGroup.NewId,
            $memberXml
        ) | Out-Null
        
        Write-Log "Added subgroup '$($childGroup.Name)' to parent group '$($parentGroup.Name)'" -Level Success
    } else {
        Write-Log "Could not find parent or child group for subgroup relationship" -Level Warning
    }
}