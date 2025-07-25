# ============================================================================
# SolarWinds Group Creation Script
# ============================================================================
# Author: Ryan Woolsey
# Date: 7/9/2025
# Version: 1.1
#
# Automates the creation of a dynamic parent group and subgroups in SolarWinds Orion.
# Each subgroup contains members filtered by node caption.
#
# Prerequisites:
# - OrionSDK PowerShell module installed (SwisPowerShell)
# - Proper SolarWinds credentials and network access
# ====================================================================

# Import required module
try {
    Import-Module SwisPowerShell -ErrorAction Stop
    Write-Host "SolarWinds PowerShell module loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to load SolarWinds PowerShell module. Please ensure OrionSDK is installed."
    exit 1
}

# ============================================================================
# CONFIGURATION SECTION
# ============================================================================

# Target SolarWinds server
$OrionServer = "DCLADVSOLARW01"

# Username
$username = "Loop1"

# Password
$password = "30DayPassword!"

# If $true, no actual changes are made—preview only
$dryRun = $true 

# Output log filename
$logFile = "SolarWinds_Update_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Writes logs to console and file
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [ConsoleColor]$Color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $Color
    Add-Content -Path $logFile -Value $logEntry
}

# Creates a new dynamic group in SolarWinds
function New-SwisDynamicGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [object]$SwisConnection,
        [Parameter(Mandatory)] [string]$GroupName,
        [string]$Description = "Group created by script.",
        [ValidateSet(0, 1, 2)] [int]$RollupMode = 0,
        [int]$RefreshInterval = 60,
        [bool]$PollingEnabled = $true,
        [Parameter(Mandatory)] [array]$Members # Array of hashtables with Name and Definition
    )

    # Validate each member definition
    foreach ($member in $Members) {
        if (-not ($member.ContainsKey("Name") -and $member.ContainsKey("Definition"))) {
            throw "Each member must have 'Name' and 'Definition' keys."
        }
    }

    # Build XML for group member definitions
    $xmlContent = @(
        "<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>"
        $Members | ForEach-Object {
            "<MemberDefinitionInfo><Name>$($_.Name)</Name><Definition>$($_.Definition)</Definition></MemberDefinitionInfo>"
        }
        "</ArrayOfMemberDefinitionInfo>"
    ) -join "`n"
    $xmlMembers = [xml]$xmlContent

    # Call SolarWinds API to create the group
    try {
        $groupId = (Invoke-SwisVerb $SwisConnection "Orion.Container" "CreateContainer" @(
            $GroupName, "Core", $RefreshInterval, $RollupMode,
            $Description, $PollingEnabled.ToString().ToLower(), $xmlMembers.DocumentElement
        )).InnerText
        Write-Host "Group '$GroupName' created successfully with ID: $groupId"
        return $groupId
    } catch {
        Write-Error "Failed to create group: $_"
    }
}

# Adds a dynamic subgroup to a parent group
function Add-SwisSubGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [object]$SwisConnection,
        [Parameter(Mandatory)] [string]$SubGroupName,
        [Parameter(Mandatory)] [int]$ParentGroupId,
        [array]$Members,
        [string]$Description = "Subgroup created by script.",
        [ValidateSet(0, 1, 2)] [int]$RollupMode = 0,
        [int]$RefreshInterval = 60,
        [bool]$PollingEnabled = $true
    )

    # Validate subgroup members
    foreach ($member in $Members) {
        if (-not ($member.ContainsKey("Name") -and $member.ContainsKey("Definition"))) {
            throw "Each member must have 'Name' and 'Definition' keys."
        }
    }
    try {
        # Build XML content for subgroup members
        $xmlContent = @(
            "<ArrayOfMemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'>"
            $Members | ForEach-Object {
                "<MemberDefinitionInfo><Name>$($_.Name)</Name><Definition>$($_.Definition)</Definition></MemberDefinitionInfo>"
            }
            "</ArrayOfMemberDefinitionInfo>"
        ) -join "`n"
        $xmlMembers = [xml]$xmlContent

        # Create the subgroup
        $subGroupId = (Invoke-SwisVerb $SwisConnection "Orion.Container" "CreateContainer" @(
            $SubGroupName, "Core", $RefreshInterval, $RollupMode,
            $Description, $PollingEnabled.ToString().ToLower(), $xmlMembers.DocumentElement
        )).InnerText
        Write-Host "Subgroup '$SubGroupName' created with ID: $subGroupId" -ForegroundColor Green

        # Add subgroup to the parent group
        $subGroupUri = Get-SwisData $SwisConnection "SELECT Uri FROM Orion.Container WHERE ContainerID=@id" @{ id = $subGroupId }
        Invoke-SwisVerb $SwisConnection "Orion.Container" "AddDefinition" @(
            $ParentGroupId,
            ([xml]"<MemberDefinitionInfo xmlns='http://schemas.solarwinds.com/2008/Orion'><Name>$SubGroupName</Name><Definition>$subGroupUri</Definition></MemberDefinitionInfo>").DocumentElement
        ) | Out-Null
        Write-Host "Subgroup '$SubGroupName' added to parent group ID $ParentGroupId" -ForegroundColor Cyan
        return $subGroupId
    } catch {
        Write-Error "Failed to create or add subgroup: $_"
        return $null
    }
}

# ============================================================================
# MAIN EXECUTION SECTION
# ============================================================================

Write-Log "Starting SolarWinds Group Creation Script" "INFO" "Cyan"
Write-Log "Dry Run Mode: $dryRun" "INFO" "Yellow"

# Connect to SolarWinds
try {
    Write-Log "Connecting to SolarWinds server: $OrionServer" "INFO" "Yellow"
    $swis = Connect-Swis -host $OrionServer -UserName $username -Password $password
    Write-Log "Successfully connected to SolarWinds" "INFO" "Green"
} catch {
    Write-Log "Failed to connect to SolarWinds: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}

# Define parent group and its children
$rootGroup = "Access"
$subGroups = @(

    [PSCustomObject]@{GroupName = "103"
        Members                 = @(
            "eordcl-des-c20202-sw",
            "eordcl-des-c20203-sw",
            "eordcl-des-c20206-sw",
            "eordcl-des-c20207-sw",
            "eordcl-des-c20209-sw",
            "eordcl-des-c20211-sw",
            "eordcl-des-c20212-sw",
            "eordcl-des-c20214-sw",
            "eordcl-des-c20216-sw",
            "eordcl-des-c20217-sw",
            "eordcl-des-c20221-sw",
            "eordcl-des-c20222-sw",
            "eordcl-des-c20223-sw",
            "eordcl-des-c20224-sw",
            "eordcl-des-c20225-sw",
            "eordcl-des-c20228-sw",
            "eordcl-des-c20229-sw",
            "eordcl-des-c20232-sw",
            "eordcl-des-c20234-sw",
            "eordcl-des-c20235-sw",
            "eordcl-des-c20237-sw",
            "eordcl-des-c20240-sw",
            "eordcl-des-c20241-sw",
            "eordcl-des-c20244-sw",
            "eordcl-des-c20301-sw",
            "eordcl-des-c20302-sw",
            "eordcl-des-c20303-sw",
            "eordcl-des-c20306-sw",
            "eordcl-des-c20307-sw",
            "eordcl-des-c20308-sw",
            "eordcl-des-c20309-sw",
            "eordcl-des-c20313-sw",
            "eordcl-des-c20314-sw",
            "eordcl-des-c20316-sw",
            "eordcl-des-c20317-sw",
            "eordcl-des-c20319-sw",
            "eordcl-des-c20322-sw",
            "eordcl-des-c20324-sw",
            "eordcl-des-c20325-sw",
            "eordcl-des-c20326-sw",
            "eordcl-des-c20327-sw",
            "eordcl-des-c20332-sw"
        )
    },

    [PSCustomObject]@{GroupName = "106"
        Members                 = @(
            "eordcl-des-6170-sw",
            "eordcl-des-6172-sw",
            "eordcl-des-6176-sw",
            "eordcl-des-6178-sw",
            "eordcl-des-6182-sw",
            "eordcl-des-6186-sw",
            "eordcl-des-6188-sw",
            "eordcl-des-6192-sw",
            "eordcl-des-6195-sw",
            "eordcl-des-6196-sw",
            "eordcl-des-6198-sw",
            "eordcl-des-6200-sw",
            "eordcl-des-6670-sw",
            "eordcl-des-6674-sw",
            "eordcl-des-6676-sw",
            "eordcl-des-6680-sw",
            "eordcl-des-6684-sw",
            "eordcl-des-6686-sw",
            "eordcl-des-6690-sw",
            "eordcl-des-6694-sw",
            "eordcl-des-6696-sw",
            "eordcl-des-6698-sw",
            "eordcl-des-6700-sw"
        )
    },

    [PSCustomObject]@{GroupName = "109"
        Members                 = @(
            "eordcl-des-7170-sw",
            "eordcl-des-7172-sw",
            "eordcl-des-7176-sw",
            "eordcl-des-7178-sw",
            "eordcl-des-7182-sw",
            "eordcl-des-7184-sw",
            "eordcl-des-7188-sw",
            "eordcl-des-7192-sw",
            "eordcl-des-7198-sw",
            "eordcl-des-7666-sw",
            "eordcl-des-7670-sw",
            "eordcl-des-7672-sw",
            "eordcl-des-7676-sw",
            "eordcl-des-7678-sw",
            "eordcl-des-7682-sw",
            "eordcl-des-7686-sw",
            "eordcl-des-7689-sw",
            "eordcl-des-7690-sw",
            "eordcl-des-7694-sw",
            "eordcl-des-8168-sw",
            "eordcl-des-8170-sw",
            "eordcl-des-8172-sw",
            "eordcl-des-8176-sw",
            "eordcl-des-8180-sw",
            "eordcl-des-8181-sw",
            "eordcl-des-8182-sw",
            "eordcl-des-8185-sw",
            "eordcl-des-8186-sw",
            "eordcl-des-8189-sw",
            "eordcl-des-8190-sw",
            "eordcl-des-8192-sw",
            "eordcl-des-8194-sw",
            "eordcl-des-8666-sw",
            "eordcl-des-8668-sw",
            "eordcl-des-8672-sw",
            "eordcl-des-8676-sw",
            "eordcl-des-8678-sw",
            "eordcl-des-8682-sw",
            "eordcl-des-8686-sw",
            "eordcl-des-8688-sw",
            "eordcl-des-8690-sw",
            "eordcl-des-8692-sw",
            "eordcl-des-9160-sw",
            "eordcl-des-9162-sw",
            "eordcl-des-9164-sw",
            "eordcl-des-9168-sw",
            "eordcl-des-9172-sw",
            "eordcl-des-9174-sw",
            "eordcl-des-9175-sw",
            "eordcl-des-9177-sw",
            "eordcl-des-9178-sw",
            "eordcl-des-9182-sw",
            "eordcl-des-9184-sw",
            "eordcl-des-9660-sw",
            "eordcl-des-9662-sw",
            "eordcl-des-9666-sw",
            "eordcl-des-9670-sw",
            "eordcl-des-9672-sw",
            "eordcl-des-9676-sw",
            "eordcl-des-9678-sw",
            "eordcl-des-9682-sw"
        )
    },

    [PSCustomObject]@{GroupName = "111"
        Members                 = @(
            "eordcl-des-10154-sw",
            "eordcl-des-10156-sw",
            "eordcl-des-10160-sw",
            "eordcl-des-10164-sw",
            "eordcl-des-10166-sw",
            "eordcl-des-10168-sw",
            "eordcl-des-10169-sw",
            "eordcl-des-10170-sw",
            "eordcl-des-10654-sw",
            "eordcl-des-10656-sw",
            "eordcl-des-10660-sw",
            "eordcl-des-10664-sw",
            "eordcl-des-10666-sw",
            "eordcl-des-10668-sw"
        )
    },

    [PSCustomObject]@{GroupName = "201"
        Members                 = @(
            "eordcl-des-c10401-sw",
            "eordcl-des-c10402-sw",
            "eordcl-des-c10403-sw",
            "eordcl-des-c10404-sw",
            "eordcl-des-c10405-sw",
            "eordcl-des-c10408-sw",
            "eordcl-des-c10701-sw",
            "eordcl-des-c10702-sw",
            "eordcl-des-c10703-sw",
            "eordcl-des-c10704-sw",
            "eordcl-des-c10705-sw",
            "eordcl-des-c10706-sw",
            "eordcl-des-c10707-sw",
            "eordcl-des-c10709-sw",
            "eordcl-des-c10710-sw",
            "eordcl-des-c10713-sw",
            "eordcl-des-c10714-sw",
            "eordcl-des-c10715-sw",
            "eordcl-des-c10716-sw",
            "eordcl-des-c10718-sw",
            "eordcl-des-c10719-sw",
            "eordcl-des-c10720-sw",
            "eordcl-des-c10723-sw",
            "eordcl-des-c10724-sw",
            "eordcl-des-c10726-sw",
            "eordcl-des-c10728-sw"
        )
    },

    [PSCustomObject]@{GroupName = "205"
        Members                 = @(
            "eordcl-des-c20401-sw",
            "eordcl-des-c20402-sw",
            "eordcl-des-c20403-sw",
            "eordcl-des-c20406-sw",
            "eordcl-des-c20409-sw",
            "eordcl-des-c20410-sw",
            "eordcl-des-c20411-sw",
            "eordcl-des-c20412-sw",
            "eordcl-des-c20415-sw",
            "eordcl-des-c20418-sw",
            "eordcl-des-c20419-sw",
            "eordcl-des-c20420-sw",
            "eordcl-des-c20421-sw",
            "eordcl-des-c20424-sw",
            "eordcl-des-c20426-sw",
            "eordcl-des-c20427-sw",
            "eordcl-des-c20430-sw",
            "eordcl-des-c20434-sw",
            "eordcl-des-c20438-sw",
            "eordcl-des-c20440-sw",
            "eordcl-des-c20501-sw",
            "eordcl-des-c20502-sw",
            "eordcl-des-c20505-sw",
            "eordcl-des-c20506-sw",
            "eordcl-des-c20508-sw",
            "eordcl-des-c20509-sw",
            "eordcl-des-c20510-sw",
            "eordcl-des-c20511-sw",
            "eordcl-des-c20515-sw",
            "eordcl-des-c20516-sw",
            "eordcl-des-c20517-sw",
            "eordcl-des-c20518-sw",
            "eordcl-des-c20519-sw",
            "eordcl-des-c20520-sw",
            "eordcl-des-c20525-sw",
            "eordcl-des-c20526-sw",
            "eordcl-des-c20527-sw",
            "eordcl-des-c20528-sw",
            "eordcl-des-c20530-sw",
            "eordcl-des-c20531-sw",
            "eordcl-des-c20540-sw",
            "eordcl-des-c20544-sw",
            "eordcl-des-c20601-sw",
            "eordcl-des-c20602-sw",
            "eordcl-des-c20603-sw",
            "eordcl-des-c20605-sw",
            "eordcl-des-c20606-sw",
            "eordcl-des-c20609-sw",
            "eordcl-des-c20610-sw",
            "eordcl-des-c20612-sw",
            "eordcl-des-c20616-sw"
        )
    },

    [PSCustomObject]@{GroupName = "208"
        Members                 = @(
            "eordcl-des-6138-sw",
            "eordcl-des-6140-sw",
            "eordcl-des-6144-sw",
            "eordcl-des-6148-sw",
            "eordcl-des-6152-sw",
            "eordcl-des-6156-sw",
            "eordcl-des-6158-sw",
            "eordcl-des-6160-sw",
            "eordcl-des-6164-sw",
            "eordcl-des-6168-sw",
            "eordcl-des-6638-sw",
            "eordcl-des-6642-sw",
            "eordcl-des-6646-sw",
            "eordcl-des-6650-sw",
            "eordcl-des-6654-sw",
            "eordcl-des-6656-sw",
            "eordcl-des-6658-sw",
            "eordcl-des-6662-sw",
            "eordcl-des-6666-sw",
            "eordcl-des-6668-sw",
            "eordcl-des-7138-sw",
            "eordcl-des-7140-sw",
            "eordcl-des-7144-sw",
            "eordcl-des-7148-sw",
            "eordcl-des-7149-sw",
            "eordcl-des-7152-sw",
            "eordcl-des-7156-sw",
            "eordcl-des-7158-sw",
            "eordcl-des-7160-sw",
            "eordcl-des-7164-sw",
            "eordcl-des-7168-sw",
            "eordcl-des-7634-sw",
            "eordcl-des-7638-sw",
            "eordcl-des-7642-sw",
            "eordcl-des-7646-sw",
            "eordcl-des-7650-sw",
            "eordcl-des-7652-sw",
            "eordcl-des-7654-sw",
            "eordcl-des-7658-sw",
            "eordcl-des-7662-sw",
            "eordcl-des-7664-sw",
            "eordcl-des-8136-sw",
            "eordcl-des-8138-sw",
            "eordcl-des-8142-sw",
            "eordcl-des-8146-sw",
            "eordcl-des-8150-sw",
            "eordcl-des-8154-sw",
            "eordcl-des-8156-sw",
            "eordcl-des-8158-sw",
            "eordcl-des-8162-sw",
            "eordcl-des-8166-sw",
            "eordcl-des-8634-sw",
            "eordcl-des-8638-sw",
            "eordcl-des-8642-sw",
            "eordcl-des-8645-sw",
            "eordcl-des-8646-sw",
            "eordcl-des-8650-sw",
            "eordcl-des-8652-sw",
            "eordcl-des-8654-sw",
            "eordcl-des-8658-sw",
            "eordcl-des-8662-sw",
            "eordcl-des-8664-sw",
            "eordcl-des-9128-sw",
            "eordcl-des-9130-sw",
            "eordcl-des-9134-sw",
            "eordcl-des-9138-sw",
            "eordcl-des-9139-sw",
            "eordcl-des-9142-sw",
            "eordcl-des-9146-sw",
            "eordcl-des-9148-sw",
            "eordcl-des-9150-sw",
            "eordcl-des-9154-sw",
            "eordcl-des-9158-sw",
            "eordcl-des-9628-sw",
            "eordcl-des-9632-sw",
            "eordcl-des-9636-sw",
            "eordcl-des-9639-sw",
            "eordcl-des-9640-sw",
            "eordcl-des-9644-sw",
            "eordcl-des-9646-sw",
            "eordcl-des-9647-sw",
            "eordcl-des-9648-sw",
            "eordcl-des-9652-sw",
            "eordcl-des-9656-sw",
            "eordcl-des-9658-sw",
            "eordcl-des-10122-sw",
            "eordcl-des-10124-sw",
            "eordcl-des-10128-sw",
            "eordcl-des-10132-sw",
            "eordcl-des-10136-sw",
            "eordcl-des-10137-sw",
            "eordcl-des-10140-sw",
            "eordcl-des-10142-sw",
            "eordcl-des-10144-sw",
            "eordcl-des-10148-sw",
            "eordcl-des-10152-sw",
            "eordcl-des-10622-sw",
            "eordcl-des-10626-sw",
            "eordcl-des-10629-sw",
            "eordcl-des-10630-sw",
            "eordcl-des-10634-sw",
            "eordcl-des-10635-sw",
            "eordcl-des-10637-sw",
            "eordcl-des-10638-sw",
            "eordcl-des-10640-sw",
            "eordcl-des-10642-sw",
            "eordcl-des-10643-sw",
            "eordcl-des-10646-sw",
            "eordcl-des-10650-sw",
            "eordcl-des-10652-sw"
        )
    },

    [PSCustomObject]@{GroupName = "301"
        Members                 = @(
            "eordcl-des-c10730-sw",
            "eordcl-des-c10734-sw",
            "eordcl-des-c10736-sw",
            "eordcl-des-c10738-sw",
            "eordcl-des-c10740-sw",
            "eordcl-des-c10746-sw",
            "eordcl-des-c10901-sw",
            "eordcl-des-c10902-sw",
            "eordcl-des-c10903-sw",
            "eordcl-des-c10906-sw",
            "eordcl-des-c10907-sw",
            "eordcl-des-c10909-sw",
            "eordcl-des-c10910-sw",
            "eordcl-des-c10911-sw",
            "eordcl-des-c10915-sw",
            "eordcl-des-c60901-sw",
            "eordcl-des-c60902-sw",
            "eordcl-des-c60904-sw",
            "eordcl-des-c60905-sw",
            "eordcl-des-c60906-sw",
            "eordcl-des-c60909-sw",
            "eordcl-des-c60910-sw",
            "eordcl-des-c60912-sw",
            "eordcl-des-c60914-sw",
            "eordcl-des-c60920-sw",
            "eordcl-des-c60924-sw",
            "eordcl-des-c60926-sw",
            "eordcl-des-c60928-sw",
            "eordcl-des-c60932-sw",
            "eordcl-des-c61001-sw",
            "eordcl-des-c61005-sw",
            "eordcl-des-c70901-sw",
            "eordcl-des-c70902-sw",
            "eordcl-des-c70903-sw",
            "eordcl-des-c70907-sw",
            "eordcl-des-c70908-sw",
            "eordcl-des-c70910-sw",
            "eordcl-des-c70913-sw",
            "eordcl-des-c70914-sw",
            "eordcl-des-c70918-sw",
            "eordcl-des-c70919-sw",
            "eordcl-des-c70920-sw",
            "eordcl-des-c70923-sw",
            "eordcl-des-c70924-sw",
            "eordcl-des-c70925-sw",
            "eordcl-des-c70930-sw",
            "eordcl-des-c70931-sw",
            "eordcl-des-c70932-sw"
        )
    },

    [PSCustomObject]@{GroupName = "303"
        Members                 = @(
            "eordcl-des-2128-sw",
            "eordcl-des-2129-sw",
            "eordcl-des-2131-sw",
            "eordcl-des-2132-sw",
            "eordcl-des-2136-sw",
            "eordcl-des-2140-sw",
            "eordcl-des-2610-sw",
            "eordcl-des-2614-sw",
            "eordcl-des-2618-sw",
            "eordcl-des-2622-sw",
            "eordcl-des-2623-sw",
            "eordcl-des-2626-sw",
            "eordcl-des-2627-sw",
            "eordcl-des-2630-sw",
            "eordcl-des-2631-sw",
            "eordcl-des-2634-sw",
            "eordcl-des-2638-sw",
            "eordcl-des-2640-sw"
        )
    },

    [PSCustomObject]@{GroupName = "309"
        Members                 = @(
            "eordcl-des-6106-sw",
            "eordcl-des-6108-sw",
            "eordcl-des-6110-sw",
            "eordcl-des-6112-sw",
            "eordcl-des-6116-sw",
            "eordcl-des-6120-sw",
            "eordcl-des-6124-sw",
            "eordcl-des-6126-sw",
            "eordcl-des-6130-sw",
            "eordcl-des-6134-sw",
            "eordcl-des-6606-sw",
            "eordcl-des-6610-sw",
            "eordcl-des-6614-sw",
            "eordcl-des-6618-sw",
            "eordcl-des-6622-sw",
            "eordcl-des-6624-sw",
            "eordcl-des-6628-sw",
            "eordcl-des-6632-sw",
            "eordcl-des-6636-sw",
            "eordcl-des-7106-sw",
            "eordcl-des-7108-sw",
            "eordcl-des-7110-sw",
            "eordcl-des-7112-sw",
            "eordcl-des-7116-sw",
            "eordcl-des-7120-sw",
            "eordcl-des-7124-sw",
            "eordcl-des-7126-sw",
            "eordcl-des-7130-sw",
            "eordcl-des-7134-sw",
            "eordcl-des-7602-sw",
            "eordcl-des-7604-sw",
            "eordcl-des-7606-sw",
            "eordcl-des-7610-sw",
            "eordcl-des-7614-sw",
            "eordcl-des-7618-sw",
            "eordcl-des-7620-sw",
            "eordcl-des-7624-sw",
            "eordcl-des-7628-sw",
            "eordcl-des-7632-sw",
            "eordcl-des-8104-sw",
            "eordcl-des-8106-sw",
            "eordcl-des-8108-sw",
            "eordcl-des-8110-sw",
            "eordcl-des-8114-sw",
            "eordcl-des-8118-sw",
            "eordcl-des-8122-sw",
            "eordcl-des-8124-sw",
            "eordcl-des-8128-sw",
            "eordcl-des-8132-sw",
            "eordcl-des-8602-sw",
            "eordcl-des-8604-sw",
            "eordcl-des-8606-sw",
            "eordcl-des-8610-sw",
            "eordcl-des-8614-sw",
            "eordcl-des-8618-sw",
            "eordcl-des-8620-sw",
            "eordcl-des-8624-sw",
            "eordcl-des-8628-sw",
            "eordcl-des-8632-sw",
            "eordcl-des-9094-sw",
            "eordcl-des-9098-sw",
            "eordcl-des-9102-sw",
            "eordcl-des-9106-sw",
            "eordcl-des-9110-sw",
            "eordcl-des-9114-sw",
            "eordcl-des-9116-sw",
            "eordcl-des-9120-sw",
            "eordcl-des-9124-sw",
            "eordcl-des-9596-sw",
            "eordcl-des-9600-sw",
            "eordcl-des-9604-sw",
            "eordcl-des-9608-sw",
            "eordcl-des-9612-sw",
            "eordcl-des-9614-sw",
            "eordcl-des-9618-sw",
            "eordcl-des-9622-sw",
            "eordcl-des-9626-sw"
        )
    },

    [PSCustomObject]@{GroupName = "311"
        Members                 = @(
            "eordcl-des-10088-sw",
            "eordcl-des-10092-sw",
            "eordcl-des-10096-sw",
            "eordcl-des-10100-sw",
            "eordcl-des-10104-sw",
            "eordcl-des-10108-sw",
            "eordcl-des-10110-sw",
            "eordcl-des-10114-sw",
            "eordcl-des-10118-sw",
            "eordcl-des-10590-sw",
            "eordcl-des-10594-sw",
            "eordcl-des-10598-sw",
            "eordcl-des-10602-sw",
            "eordcl-des-10606-sw",
            "eordcl-des-10608-sw",
            "eordcl-des-10612-sw",
            "eordcl-des-10616-sw",
            "eordcl-des-10620-sw"
        )
    },

    [PSCustomObject]@{GroupName = "401"
        Members                 = @(
            "eordcl-des-c11051-sw",
            "eordcl-des-c11055-sw",
            "eordcl-des-c11059-sw",
            "eordcl-des-c11060-sw",
            "eordcl-des-c11062-sw",
            "eordcl-des-c11063-sw",
            "eordcl-des-c11065-sw",
            "eordcl-des-c11067-sw",
            "eordcl-des-c11068-sw",
            "eordcl-des-c11070-sw",
            "eordcl-des-c11071-sw",
            "eordcl-des-c11075-sw",
            "eordcl-des-c11076-sw",
            "eordcl-des-c11078-sw",
            "eordcl-des-c11079-sw",
            "eordcl-des-c11081-sw",
            "eordcl-des-c11082-sw",
            "eordcl-des-c11085-sw",
            "eordcl-des-c11086-sw",
            "eordcl-des-c11090-sw",
            "eordcl-des-c11091-sw",
            "eordcl-des-c11094-sw",
            "eordcl-des-c11095-sw",
            "eordcl-des-c11096-sw",
            "eordcl-des-c11097-sw",
            "eordcl-des-c11100-sw",
            "eordcl-des-c11102-sw",
            "eordcl-des-c11103-sw",
            "eordcl-des-c11105-sw",
            "eordcl-des-c11106-sw",
            "eordcl-des-c11110-sw",
            "eordcl-des-c11112-sw",
            "eordcl-des-c11114-sw",
            "eordcl-des-c11116-sw",
            "eordcl-des-c11122-sw",
            "eordcl-des-c11124-sw",
            "eordcl-des-c61002-sw",
            "eordcl-des-c61006-sw",
            "eordcl-des-c61007-sw",
            "eordcl-des-c61010-sw",
            "eordcl-des-c61012-sw",
            "eordcl-des-c61013-sw",
            "eordcl-des-c61014-sw",
            "eordcl-des-c61015-sw",
            "eordcl-des-c61016-sw",
            "eordcl-des-c61021-sw",
            "eordcl-des-c61022-sw",
            "eordcl-des-c61023-sw",
            "eordcl-des-c61024-sw",
            "eordcl-des-c61029-sw",
            "eordcl-des-c61030-sw",
            "eordcl-des-c61031-sw",
            "eordcl-des-c61032-sw",
            "eordcl-des-c61037-sw",
            "eordcl-des-c61038-sw",
            "eordcl-des-c61040-sw",
            "eordcl-des-c61046-sw",
            "eordcl-des-c61048-sw",
            "eordcl-des-c61101-sw",
            "eordcl-des-c61104-sw",
            "eordcl-des-c61106-sw",
            "eordcl-des-c61107-sw",
            "eordcl-des-c61109-sw",
            "eordcl-des-c61112-sw",
            "eordcl-des-c61114-sw",
            "eordcl-des-c61115-sw",
            "eordcl-des-c61117-sw",
            "eordcl-des-c61119-sw",
            "eordcl-des-c61120-sw",
            "eordcl-des-c61122-sw",
            "eordcl-des-c71003-sw",
            "eordcl-des-c71004-sw",
            "eordcl-des-c71005-sw",
            "eordcl-des-c71007-sw",
            "eordcl-des-c71008-sw",
            "eordcl-des-c71009-sw",
            "eordcl-des-c71012-sw",
            "eordcl-des-c71013-sw",
            "eordcl-des-c71014-sw",
            "eordcl-des-c71016-sw",
            "eordcl-des-c71017-sw",
            "eordcl-des-c71018-sw",
            "eordcl-des-c71021-sw",
            "eordcl-des-c71022-sw",
            "eordcl-des-c71024-sw",
            "eordcl-des-c71025-sw",
            "eordcl-des-c71028-sw",
            "eordcl-des-c71032-sw",
            "eordcl-des-c71036-sw",
            "eordcl-des-c71040-sw",
            "eordcl-des-c71042-sw",
            "eordcl-des-c71101-sw",
            "eordcl-des-c71102-sw",
            "eordcl-des-c71103-sw",
            "eordcl-des-c71106-sw",
            "eordcl-des-c71107-sw",
            "eordcl-des-c71110-sw",
            "eordcl-des-c71111-sw",
            "eordcl-des-c71114-sw"
        )
    },

    [PSCustomObject]@{GroupName = "402"
        Members                 = @(
            "eordcl-des-2582-sw",
            "eordcl-des-2586-sw",
            "eordcl-des-2590-sw",
            "eordcl-des-2594-sw",
            "eordcl-des-2598-sw",
            "eordcl-des-2602-sw",
            "eordcl-des-2606-sw"
        )
    },

    [PSCustomObject]@{GroupName = "404"
        Members                 = @(
            "eordcl-des-6076-sw"
        )
    },

    [PSCustomObject]@{GroupName = "409"
        Members                 = @(
            "eordcl-des-6078-sw",
            "eordcl-des-6080-sw",
            "eordcl-des-6082-sw",
            "eordcl-des-6086-sw",
            "eordcl-des-6090-sw",
            "eordcl-des-6094-sw",
            "eordcl-des-6098-sw",
            "eordcl-des-6102-sw",
            "eordcl-des-6576-sw",
            "eordcl-des-6578-sw",
            "eordcl-des-6582-sw",
            "eordcl-des-6586-sw",
            "eordcl-des-6590-sw",
            "eordcl-des-6594-sw",
            "eordcl-des-6598-sw",
            "eordcl-des-6602-sw",
            "eordcl-des-7078-sw",
            "eordcl-des-7080-sw",
            "eordcl-des-7082-sw",
            "eordcl-des-7086-sw",
            "eordcl-des-7090-sw",
            "eordcl-des-7094-sw",
            "eordcl-des-7098-sw",
            "eordcl-des-7102-sw",
            "eordcl-des-7574-sw",
            "eordcl-des-7576-sw",
            "eordcl-des-7580-sw",
            "eordcl-des-7584-sw",
            "eordcl-des-7588-sw",
            "eordcl-des-7592-sw",
            "eordcl-des-7596-sw",
            "eordcl-des-7600-sw",
            "eordcl-des-8076-sw",
            "eordcl-des-8078-sw",
            "eordcl-des-8080-sw",
            "eordcl-des-8084-sw",
            "eordcl-des-8088-sw",
            "eordcl-des-8092-sw",
            "eordcl-des-8093-sw",
            "eordcl-des-8096-sw",
            "eordcl-des-8100-sw",
            "eordcl-des-8574-sw",
            "eordcl-des-8576-sw",
            "eordcl-des-8580-sw",
            "eordcl-des-8583-sw",
            "eordcl-des-8584-sw",
            "eordcl-des-8588-sw",
            "eordcl-des-8591-sw",
            "eordcl-des-8592-sw",
            "eordcl-des-8596-sw",
            "eordcl-des-8599-sw",
            "eordcl-des-8600-sw",
            "eordcl-des-9066-sw",
            "eordcl-des-9068-sw",
            "eordcl-des-9070-sw",
            "eordcl-des-9074-sw",
            "eordcl-des-9077-sw",
            "eordcl-des-9078-sw",
            "eordcl-des-9082-sw",
            "eordcl-des-9086-sw",
            "eordcl-des-9087-sw",
            "eordcl-des-9089-sw",
            "eordcl-des-9090-sw",
            "eordcl-des-9566-sw",
            "eordcl-des-9568-sw",
            "eordcl-des-9572-sw",
            "eordcl-des-9576-sw",
            "eordcl-des-9577-sw",
            "eordcl-des-9580-sw",
            "eordcl-des-9584-sw",
            "eordcl-des-9587-sw",
            "eordcl-des-9588-sw",
            "eordcl-des-9592-sw"
        )
    },

    [PSCustomObject]@{GroupName = "414"
        Members                 = @(
            "eordcl-des-10060-sw",
            "eordcl-des-10062-sw",
            "eordcl-des-10064-sw",
            "eordcl-des-10068-sw",
            "eordcl-des-10071-sw",
            "eordcl-des-10072-sw",
            "eordcl-des-10073-sw",
            "eordcl-des-10076-sw",
            "eordcl-des-10080-sw",
            "eordcl-des-10084-sw",
            "eordcl-des-10560-sw",
            "eordcl-des-10562-sw",
            "eordcl-des-10566-sw",
            "eordcl-des-10570-sw",
            "eordcl-des-10571-sw",
            "eordcl-des-10573-sw",
            "eordcl-des-10574-sw",
            "eordcl-des-10578-sw",
            "eordcl-des-10582-sw",
            "eordcl-des-10586-sw",
            "eordcl-des-14000-a-sw",
            "eordcl-des-14000-b-sw"
        )
    },

    [PSCustomObject]@{GroupName = "503"
        Members                 = @(
            "eordcl-des-2050-sw",
            "eordcl-des-2052-sw",
            "eordcl-des-2053-sw",
            "eordcl-des-2055-sw",
            "eordcl-des-2056-sw",
            "eordcl-des-2060-sw",
            "eordcl-des-2061-sw",
            "eordcl-des-2062-sw",
            "eordcl-des-2550-sw",
            "eordcl-des-2551-sw",
            "eordcl-des-2554-sw",
            "eordcl-des-2557-sw",
            "eordcl-des-2558-sw",
            "eordcl-des-2559-sw",
            "eordcl-des-2562-sw",
            "eordcl-des-2563-sw",
            "eordcl-des-2565-sw",
            "eordcl-des-2566-sw",
            "eordcl-des-2569-sw",
            "eordcl-des-2570-sw",
            "eordcl-des-2573-sw",
            "eordcl-des-2574-sw",
            "eordcl-des-2578-sw"
        )
    },

    [PSCustomObject]@{GroupName = "504"
        Members                 = @(
            "eordcl-des-6048-sw",
            "eordcl-des-6050-sw",
            "eordcl-des-6054-sw",
            "eordcl-des-6058-sw",
            "eordcl-des-6062-sw",
            "eordcl-des-6066-sw",
            "eordcl-des-6068-sw",
            "eordcl-des-6072-sw",
            "eordcl-des-6546-sw",
            "eordcl-des-6550-sw",
            "eordcl-des-6554-sw",
            "eordcl-des-6558-sw",
            "eordcl-des-6562-sw",
            "eordcl-des-6564-sw",
            "eordcl-des-6568-sw",
            "eordcl-des-6572-sw",
            "eordcl-des-6574-sw"
        )
    },

    [PSCustomObject]@{GroupName = "509"
        Members                 = @(
            "eordcl-des-7048-sw",
            "eordcl-des-7050-sw",
            "eordcl-des-7054-sw",
            "eordcl-des-7058-sw",
            "eordcl-des-7062-sw",
            "eordcl-des-7066-sw",
            "eordcl-des-7068-sw",
            "eordcl-des-7072-sw",
            "eordcl-des-7076-sw",
            "eordcl-des-7544-sw",
            "eordcl-des-7548-sw",
            "eordcl-des-7552-sw",
            "eordcl-des-7556-sw",
            "eordcl-des-7560-sw",
            "eordcl-des-7562-sw",
            "eordcl-des-7566-sw",
            "eordcl-des-7570-sw",
            "eordcl-des-7572-sw",
            "eordcl-des-8046-sw",
            "eordcl-des-8048-sw",
            "eordcl-des-8052-sw",
            "eordcl-des-8056-sw",
            "eordcl-des-8060-sw",
            "eordcl-des-8064-sw",
            "eordcl-des-8066-sw",
            "eordcl-des-8070-sw",
            "eordcl-des-8073-sw",
            "eordcl-des-8074-sw",
            "eordcl-des-8544-sw",
            "eordcl-des-8548-sw",
            "eordcl-des-8552-sw",
            "eordcl-des-8556-sw",
            "eordcl-des-8560-sw",
            "eordcl-des-8562-sw",
            "eordcl-des-8566-sw",
            "eordcl-des-8570-sw",
            "eordcl-des-8572-sw",
            "eordcl-des-9036-sw",
            "eordcl-des-9038-sw",
            "eordcl-des-9042-sw",
            "eordcl-des-9046-sw",
            "eordcl-des-9050-sw",
            "eordcl-des-9054-sw",
            "eordcl-des-9056-sw",
            "eordcl-des-9057-sw",
            "eordcl-des-9059-sw",
            "eordcl-des-9060-sw",
            "eordcl-des-9061-sw",
            "eordcl-des-9063-sw",
            "eordcl-des-9064-sw",
            "eordcl-des-9536-sw",
            "eordcl-des-9540-sw",
            "eordcl-des-9544-sw",
            "eordcl-des-9548-sw",
            "eordcl-des-9552-sw",
            "eordcl-des-9554-sw",
            "eordcl-des-9557-sw",
            "eordcl-des-9558-sw",
            "eordcl-des-9561-sw",
            "eordcl-des-9562-sw",
            "eordcl-des-9564-sw"
        )
    },

    [PSCustomObject]@{GroupName = "514"
        Members                 = @(
            "eordcl-des-10030-sw",
            "eordcl-des-10032-sw",
            "eordcl-des-10036-sw",
            "eordcl-des-10040-sw",
            "eordcl-des-10044-sw",
            "eordcl-des-10048-sw",
            "eordcl-des-10050-sw",
            "eordcl-des-10054-sw",
            "eordcl-des-10058-sw",
            "eordcl-des-10530-sw",
            "eordcl-des-10534-sw",
            "eordcl-des-10538-sw",
            "eordcl-des-10542-sw",
            "eordcl-des-10546-sw",
            "eordcl-des-10548-sw",
            "eordcl-des-10552-sw",
            "eordcl-des-10556-sw",
            "eordcl-des-10558-sw",
            "eordcl-des-11042-sw",
            "eordcl-des-11044-sw",
            "eordcl-des-11048-sw",
            "eordcl-des-11052-sw",
            "eordcl-des-11056-sw",
            "eordcl-des-11540-sw",
            "eordcl-des-11544-sw",
            "eordcl-des-11548-sw",
            "eordcl-des-11552-sw",
            "eordcl-des-11554-sw",
            "eordcl-des-12024-sw",
            "eordcl-des-12026-sw",
            "eordcl-des-12028-sw",
            "eordcl-des-12032-sw",
            "eordcl-des-12524-sw",
            "eordcl-des-12526-sw",
            "eordcl-des-12530-sw",
            "eordcl-des-12534-sw",
            "eordcl-des-13020-sw",
            "eordcl-des-13022-sw",
            "eordcl-des-13024-sw",
            "eordcl-des-13028-sw",
            "eordcl-des-13520-sw",
            "eordcl-des-13522-sw",
            "eordcl-des-13526-sw",
            "eordcl-des-13528-sw"
        )
    },

    [PSCustomObject]@{GroupName = "533"
        Members                 = @(
            "eordcl-des-c11201-sw",
            "eordcl-des-c11207-sw",
            "eordcl-des-c11209-sw",
            "eordcl-des-c11211-sw",
            "eordcl-des-c11215-sw",
            "eordcl-des-c11219-sw",
            "eordcl-des-c11304-sw",
            "eordcl-des-c11306-sw",
            "eordcl-des-c61201-sw",
            "eordcl-des-c61202-sw",
            "eordcl-des-c61204-sw",
            "eordcl-des-c61205-sw",
            "eordcl-des-c61209-sw",
            "eordcl-des-c61210-sw",
            "eordcl-des-c61211-sw",
            "eordcl-des-c61212-sw",
            "eordcl-des-c61215-sw",
            "eordcl-des-c61216-sw",
            "eordcl-des-c61218-sw",
            "eordcl-des-c61219-sw",
            "eordcl-des-c61220-sw",
            "eordcl-des-c61223-sw",
            "eordcl-des-c61224-sw",
            "eordcl-des-c61225-sw",
            "eordcl-des-c61228-sw",
            "eordcl-des-c61230-sw",
            "eordcl-des-c61236-sw",
            "eordcl-des-c61238-sw",
            "eordcl-des-c61240-sw",
            "eordcl-des-c61242-sw",
            "eordcl-des-c61302-sw",
            "eordcl-des-c61303-sw",
            "eordcl-des-c61304-sw",
            "eordcl-des-c61305-sw",
            "eordcl-des-c61306-sw",
            "eordcl-des-c61307-sw",
            "eordcl-des-c61310-sw",
            "eordcl-des-c61311-sw",
            "eordcl-des-c61314-sw",
            "eordcl-des-c61315-sw",
            "eordcl-des-c61316-sw",
            "eordcl-des-c61319-sw",
            "eordcl-des-c61322-sw",
            "eordcl-des-c61324-sw",
            "eordcl-des-c61328-sw",
            "eordcl-des-c61332-sw",
            "eordcl-des-c61334-sw",
            "eordcl-des-c61401-sw",
            "eordcl-des-c61404-sw",
            "eordcl-des-c61406-sw",
            "eordcl-des-c61407-sw",
            "eordcl-des-c61408-sw",
            "eordcl-des-c61411-sw",
            "eordcl-des-c61413-sw",
            "eordcl-des-c61414-sw",
            "eordcl-des-c61415-sw",
            "eordcl-des-c61416-sw",
            "eordcl-des-c61419-sw",
            "eordcl-des-c61422-sw",
            "eordcl-des-c61423-sw",
            "eordcl-des-c61424-sw",
            "eordcl-des-c61425-sw",
            "eordcl-des-c61426-sw",
            "eordcl-des-c61427-sw",
            "eordcl-des-c61430-sw",
            "eordcl-des-c61434-sw",
            "eordcl-des-c61436-sw",
            "eordcl-des-c61442-sw",
            "eordcl-des-c61444-sw",
            "eordcl-des-c71201-sw",
            "eordcl-des-c71202-sw",
            "eordcl-des-c71205-sw",
            "eordcl-des-c71206-sw",
            "eordcl-des-c71207-sw",
            "eordcl-des-c71210-sw",
            "eordcl-des-c71211-sw",
            "eordcl-des-c71214-sw",
            "eordcl-des-c71215-sw",
            "eordcl-des-c71220-sw",
            "eordcl-des-c71224-sw",
            "eordcl-des-c71226-sw",
            "eordcl-des-c71228-sw",
            "eordcl-des-c71230-sw",
            "eordcl-des-c71236-sw",
            "eordcl-des-c71238-sw",
            "eordcl-des-c71240-sw",
            "eordcl-des-c71246-sw",
            "eordcl-des-c71248-sw",
            "eordcl-des-c71301-sw",
            "eordcl-des-c71302-sw",
            "eordcl-des-c71304-sw",
            "eordcl-des-c71305-sw",
            "eordcl-des-c71307-sw",
            "eordcl-des-c71308-sw",
            "eordcl-des-c71310-sw",
            "eordcl-des-c71311-sw",
            "eordcl-des-c71312-sw",
            "eordcl-des-c71314-sw",
            "eordcl-des-c71315-sw",
            "eordcl-des-c71320-sw",
            "eordcl-des-c71322-sw",
            "eordcl-des-c71326-sw",
            "eordcl-des-c71401-sw",
            "eordcl-des-c71402-sw",
            "eordcl-des-c71404-sw",
            "eordcl-des-c71407-sw",
            "eordcl-des-c71408-sw",
            "eordcl-des-c71409-sw",
            "eordcl-des-c71410-sw",
            "eordcl-des-c71411-sw",
            "eordcl-des-c71412-sw",
            "eordcl-des-c71414-sw",
            "eordcl-des-c71417-sw",
            "eordcl-des-c71418-sw",
            "eordcl-des-c71419-sw",
            "eordcl-des-c71420-sw",
            "eordcl-des-c71422-sw",
            "eordcl-des-c71423-sw",
            "eordcl-des-c71428-sw",
            "eordcl-des-c71430-sw"
        )
    },

    [PSCustomObject]@{GroupName = "601"
        Members                 = @(
            "eordcl-des-c11601-sw",
            "eordcl-des-c11602-sw",
            "eordcl-des-c11603-sw",
            "eordcl-des-c11604-sw",
            "eordcl-des-c11608-sw",
            "eordcl-des-c11610-sw",
            "eordcl-des-c11616-sw",
            "eordcl-des-c11620-sw",
            "eordcl-des-c11624-sw",
            "eordcl-des-c11701-sw",
            "eordcl-des-c11704-sw",
            "eordcl-des-c11705-sw",
            "eordcl-des-c11708-sw",
            "eordcl-des-c11710-sw",
            "eordcl-des-c61601-sw",
            "eordcl-des-c61605-sw",
            "eordcl-des-c61606-sw",
            "eordcl-des-c61608-sw",
            "eordcl-des-c61609-sw",
            "eordcl-des-c61612-sw",
            "eordcl-des-c61614-sw",
            "eordcl-des-c61618-sw",
            "eordcl-des-c61622-sw",
            "eordcl-des-c61626-sw",
            "eordcl-des-c71602-sw",
            "eordcl-des-c71603-sw",
            "eordcl-des-c71606-sw",
            "eordcl-des-c71607-sw",
            "eordcl-des-c71609-sw",
            "eordcl-des-c71610-sw",
            "eordcl-des-c71611-sw",
            "eordcl-des-c71612-sw",
            "eordcl-des-c71615-sw",
            "eordcl-des-c71618-sw",
            "eordcl-des-c71620-sw",
            "eordcl-des-c71622-sw",
            "eordcl-des-c71624-sw",
            "eordcl-des-c71702-sw",
            "eordcl-des-c71703-sw",
            "eordcl-des-c71705-sw",
            "eordcl-des-c71706-sw",
            "eordcl-des-c71708-sw",
            "eordcl-des-c71709-sw",
            "eordcl-des-c71711-sw",
            "eordcl-des-c71714-sw",
            "eordcl-des-c71717-sw",
            "eordcl-des-c71718-sw",
            "eordcl-des-c71719-sw",
            "eordcl-des-c71720-sw",
            "eordcl-des-c71722-sw",
            "eordcl-des-c71723-sw",
            "eordcl-des-c71724-sw",
            "eordcl-des-c71727-sw",
            "eordcl-des-c71728-sw",
            "eordcl-des-c71729-sw",
            "eordcl-des-c71730-sw"
        )
    },

    [PSCustomObject]@{GroupName = "607"
        Members                 = @(
            "eordcl-des-6020-sw",
            "eordcl-des-6024-sw",
            "eordcl-des-6026-sw",
            "eordcl-des-6028-sw",
            "eordcl-des-6032-sw",
            "eordcl-des-6036-sw",
            "eordcl-des-6040-sw",
            "eordcl-des-6044-sw",
            "eordcl-des-6520-sw",
            "eordcl-des-6522-sw",
            "eordcl-des-6524-sw",
            "eordcl-des-6525-sw",
            "eordcl-des-6528-sw",
            "eordcl-des-6531-sw",
            "eordcl-des-6532-sw",
            "eordcl-des-6536-sw",
            "eordcl-des-6540-sw",
            "eordcl-des-6544-sw",
            "eordcl-des-7018-sw",
            "eordcl-des-7019-sw",
            "eordcl-des-7020-sw",
            "eordcl-des-7021-sw",
            "eordcl-des-7024-sw",
            "eordcl-des-7027-sw",
            "eordcl-des-7028-sw",
            "eordcl-des-7029-sw",
            "eordcl-des-7032-sw",
            "eordcl-des-7036-sw",
            "eordcl-des-7037-sw",
            "eordcl-des-7039-sw",
            "eordcl-des-7040-sw",
            "eordcl-des-7044-sw",
            "eordcl-des-7514-sw",
            "eordcl-des-7517-sw",
            "eordcl-des-7518-sw",
            "eordcl-des-7522-sw",
            "eordcl-des-7523-sw",
            "eordcl-des-7525-sw",
            "eordcl-des-7526-sw",
            "eordcl-des-7530-sw",
            "eordcl-des-7533-sw",
            "eordcl-des-7534-sw",
            "eordcl-des-7538-sw",
            "eordcl-des-7542-sw"
        )
    },

    [PSCustomObject]@{GroupName = "609"
        Members                 = @(
            "eordcl-des-8016-sw",
            "eordcl-des-8017-sw",
            "eordcl-des-8018-sw",
            "eordcl-des-8019-sw",
            "eordcl-des-8021-sw",
            "eordcl-des-8022-sw",
            "eordcl-des-8026-sw",
            "eordcl-des-8027-sw",
            "eordcl-des-8029-sw",
            "eordcl-des-8030-sw",
            "eordcl-des-8031-sw",
            "eordcl-des-8033-sw",
            "eordcl-des-8034-sw",
            "eordcl-des-8038-sw",
            "eordcl-des-8042-sw",
            "eordcl-des-8514-sw",
            "eordcl-des-8518-sw",
            "eordcl-des-8519-sw",
            "eordcl-des-8522-sw",
            "eordcl-des-8526-sw",
            "eordcl-des-8527-sw",
            "eordcl-des-8530-sw",
            "eordcl-des-8531-sw",
            "eordcl-des-8534-sw",
            "eordcl-des-8538-sw",
            "eordcl-des-8542-sw",
            "eordcl-des-9006-sw",
            "eordcl-des-9008-sw",
            "eordcl-des-9012-sw",
            "eordcl-des-9013-sw",
            "eordcl-des-9015-sw",
            "eordcl-des-9016-sw",
            "eordcl-des-9017-sw",
            "eordcl-des-9019-sw",
            "eordcl-des-9020-sw",
            "eordcl-des-9024-sw",
            "eordcl-des-9025-sw",
            "eordcl-des-9027-sw",
            "eordcl-des-9028-sw",
            "eordcl-des-9032-sw",
            "eordcl-des-9506-sw",
            "eordcl-des-9510-sw",
            "eordcl-des-9513-sw",
            "eordcl-des-9514-sw",
            "eordcl-des-9515-sw",
            "eordcl-des-9518-sw",
            "eordcl-des-9522-sw",
            "eordcl-des-9525-sw",
            "eordcl-des-9526-sw",
            "eordcl-des-9530-sw",
            "eordcl-des-9534-sw",
            "eordcl-des-10000-sw",
            "eordcl-des-10002-sw",
            "eordcl-des-10006-sw",
            "eordcl-des-10010-sw",
            "eordcl-des-10011-sw",
            "eordcl-des-10013-sw",
            "eordcl-des-10014-sw",
            "eordcl-des-10015-sw",
            "eordcl-des-10018-sw",
            "eordcl-des-10022-sw",
            "eordcl-des-10026-sw",
            "eordcl-des-10304-sw",
            "eordcl-des-10308-sw",
            "eordcl-des-10310-sw",
            "eordcl-des-10500-sw",
            "eordcl-des-10504-sw",
            "eordcl-des-10508-sw",
            "eordcl-des-10512-sw",
            "eordcl-des-10513-sw",
            "eordcl-des-10515-sw",
            "eordcl-des-10516-sw",
            "eordcl-des-10520-sw",
            "eordcl-des-10524-sw",
            "eordcl-des-10528-sw"
        )
    },

    [PSCustomObject]@{GroupName = "613"
        Members                 = @(
            "eordcl-des-11012-sw",
            "eordcl-des-11014-sw",
            "eordcl-des-11018-sw",
            "eordcl-des-11019-sw",
            "eordcl-des-11021-sw",
            "eordcl-des-11022-sw",
            "eordcl-des-11023-sw",
            "eordcl-des-11025-sw",
            "eordcl-des-11026-sw",
            "eordcl-des-11030-sw",
            "eordcl-des-11031-sw",
            "eordcl-des-11033-sw",
            "eordcl-des-11034-sw",
            "eordcl-des-11038-sw",
            "eordcl-des-11510-sw",
            "eordcl-des-11511-sw",
            "eordcl-des-11514-sw",
            "eordcl-des-11518-sw",
            "eordcl-des-11519-sw",
            "eordcl-des-11521-sw",
            "eordcl-des-11522-sw",
            "eordcl-des-11526-sw",
            "eordcl-des-11529-sw",
            "eordcl-des-11530-sw",
            "eordcl-des-11534-sw",
            "eordcl-des-11538-sw",
            "eordcl-des-12000-sw",
            "eordcl-des-12002-sw",
            "eordcl-des-12004-sw",
            "eordcl-des-12006-sw",
            "eordcl-des-12008-sw",
            "eordcl-des-12012-sw",
            "eordcl-des-12016-sw",
            "eordcl-des-12020-sw",
            "eordcl-des-12022-sw",
            "eordcl-des-12500-sw",
            "eordcl-des-12502-sw",
            "eordcl-des-12504-sw",
            "eordcl-des-12506-sw",
            "eordcl-des-12510-sw",
            "eordcl-des-12514-sw",
            "eordcl-des-12518-sw",
            "eordcl-des-12520-sw",
            "eordcl-des-12522-sw",
            "eordcl-des-13000-a-sw",
            "eordcl-des-13000-b-sw",
            "eordcl-des-13002-sw",
            "eordcl-des-13004-sw",
            "eordcl-des-13008-sw",
            "eordcl-des-13012-sw",
            "eordcl-des-13014-sw",
            "eordcl-des-13016-sw",
            "eordcl-des-13500-a-sw",
            "eordcl-des-13500-b-sw",
            "eordcl-des-13502-sw",
            "eordcl-des-13506-sw",
            "eordcl-des-13508-sw",
            "eordcl-des-13510-sw",
            "eordcl-des-13514-sw",
            "eordcl-des-13518-sw"
        )
    },

    [PSCustomObject]@{GroupName = "702"
        Members                 = @(
            "eordcl-des-c31801-sw",
            "eordcl-des-c31803-sw",
            "eordcl-des-c31804-sw",
            "eordcl-des-c31807-sw",
            "eordcl-des-c31808-sw",
            "eordcl-des-c31809-sw",
            "eordcl-des-c31810-sw",
            "eordcl-des-c31814-sw",
            "eordcl-des-c31815-sw",
            "eordcl-des-c31816-sw",
            "eordcl-des-c31817-sw",
            "eordcl-des-c31822-sw",
            "eordcl-des-c31902-sw",
            "eordcl-des-c31903-sw",
            "eordcl-des-c31906-sw",
            "eordcl-des-c31907-sw",
            "eordcl-des-c31909-sw",
            "eordcl-des-c31912-sw",
            "eordcl-des-c31913-sw",
            "eordcl-des-c31915-sw",
            "eordcl-des-c31916-sw",
            "eordcl-des-c31918-sw",
            "eordcl-des-c31919-sw",
            "eordcl-des-c31920-sw",
            "eordcl-des-c31923-sw",
            "eordcl-des-c31924-sw",
            "eordcl-des-c31925-sw",
            "eordcl-des-c71721-sw"
        )
    },

    [PSCustomObject]@{GroupName = "706"
        Members                 = @(
            "eordcl-des-6000-sw",
            "eordcl-des-6002-sw",
            "eordcl-des-6004-sw",
            "eordcl-des-6006-sw",
            "eordcl-des-6008-sw",
            "eordcl-des-6011-sw",
            "eordcl-des-6012-sw",
            "eordcl-des-6013-sw",
            "eordcl-des-6016-sw",
            "eordcl-des-6018-sw",
            "eordcl-des-6500-sw",
            "eordcl-des-6502-sw",
            "eordcl-des-6504-sw",
            "eordcl-des-6508-sw",
            "eordcl-des-6512-sw",
            "eordcl-des-6514-sw",
            "eordcl-des-6516-sw",
            "eordcl-des-c41801-sw",
            "eordcl-des-c41802-sw",
            "eordcl-des-c41804-sw",
            "eordcl-des-c41805-sw",
            "eordcl-des-c41806-sw",
            "eordcl-des-c41809-sw",
            "eordcl-des-c41811-sw",
            "eordcl-des-c41812-sw",
            "eordcl-des-c41814-sw",
            "eordcl-des-c41815-sw",
            "eordcl-des-c41820-sw",
            "eordcl-des-c41821-sw",
            "eordcl-des-c41823-sw",
            "eordcl-des-c41824-sw",
            "eordcl-des-c41827-sw",
            "eordcl-des-c41828-sw",
            "eordcl-des-c41831-sw",
            "eordcl-des-c41901-sw",
            "eordcl-des-c41904-sw",
            "eordcl-des-c41906-sw",
            "eordcl-des-c41907-sw",
            "eordcl-des-c41909-sw",
            "eordcl-des-c41910-sw",
            "eordcl-des-c41913-sw",
            "eordcl-des-c41914-sw",
            "eordcl-des-c41916-sw",
            "eordcl-des-c41917-sw",
            "eordcl-des-c41922-sw",
            "eordcl-des-c81801-sw",
            "eordcl-des-c81802-sw",
            "eordcl-des-c81805-sw",
            "eordcl-des-c81806-sw",
            "eordcl-des-c81807-sw",
            "eordcl-des-c81808-sw",
            "eordcl-des-c81809-sw",
            "eordcl-des-c81810-sw",
            "eordcl-des-c81811-sw",
            "eordcl-des-c81813-sw",
            "eordcl-des-c81815-sw",
            "eordcl-des-c81816-sw",
            "eordcl-des-c81818-sw",
            "eordcl-des-c81819-sw",
            "eordcl-des-c81821-sw",
            "eordcl-des-c81822-sw",
            "eordcl-des-c81825-sw",
            "eordcl-des-c81826-sw",
            "eordcl-des-c81827-sw",
            "eordcl-des-c81828-sw",
            "eordcl-des-c81832-sw",
            "eordcl-des-c81833-sw",
            "eordcl-des-c81834-sw",
            "eordcl-des-c81835-sw",
            "eordcl-des-c81901-sw",
            "eordcl-des-c81904-sw",
            "eordcl-des-c81905-sw",
            "eordcl-des-c81906-sw",
            "eordcl-des-c81907-sw",
            "eordcl-des-c81908-sw",
            "eordcl-des-c81910-sw",
            "eordcl-des-c81911-sw",
            "eordcl-des-c81913-sw",
            "eordcl-des-c81915-sw",
            "eordcl-des-c81916-sw",
            "eordcl-des-c81917-sw",
            "eordcl-des-c81918-sw",
            "eordcl-des-c81920-sw"
        )
    },

    [PSCustomObject]@{GroupName = "709"
        Members                 = @(
            "eordcl-des-7000-sw",
            "eordcl-des-7001-sw",
            "eordcl-des-7002-sw",
            "eordcl-des-7003-sw",
            "eordcl-des-7004-sw",
            "eordcl-des-7006-sw",
            "eordcl-des-7008-sw",
            "eordcl-des-7010-sw",
            "eordcl-des-7014-sw",
            "eordcl-des-7500-sw",
            "eordcl-des-7501-sw",
            "eordcl-des-7502-sw",
            "eordcl-des-7504-sw",
            "eordcl-des-7506-sw",
            "eordcl-des-7508-sw",
            "eordcl-des-7510-sw",
            "eordcl-des-7511-sw",
            "eordcl-des-7512-sw",
            "eordcl-des-8000-sw",
            "eordcl-des-8002-sw",
            "eordcl-des-8003-sw",
            "eordcl-des-8004-sw",
            "eordcl-des-8006-sw",
            "eordcl-des-8008-sw",
            "eordcl-des-8010-sw",
            "eordcl-des-8012-sw",
            "eordcl-des-8500-sw",
            "eordcl-des-8502-sw",
            "eordcl-des-8504-sw",
            "eordcl-des-8506-sw",
            "eordcl-des-8508-sw",
            "eordcl-des-8510-sw",
            "eordcl-des-9000-sw",
            "eordcl-des-9002-sw",
            "eordcl-des-9500-sw",
            "eordcl-des-9504-sw",
            "eordcl-des-10301-sw",
            "eordcl-des-10302-sw",
            "eordcl-des-11000-sw",
            "eordcl-des-11002-sw",
            "eordcl-des-11004-sw",
            "eordcl-des-11006-sw",
            "eordcl-des-11008-sw",
            "eordcl-des-11010-sw",
            "eordcl-des-11500-sw",
            "eordcl-des-11502-sw",
            "eordcl-des-11504-sw",
            "eordcl-des-11506-sw",
            "eordcl-des-11508-sw",
            "eordcl-des-91801-sw",
            "eordcl-des-91802-sw"
        )
    },

    [PSCustomObject]@{GroupName = "LIFT"
        Members                 = @(
            "eordcl-des-212elv-sl26-c-sw",
            "eordcl-des-212elv-sl26-t-sw",
            "eordcl-des-212elv-sl27-c-sw",
            "eordcl-des-212elv-sl27-t-sw",
            "eordcl-des-214elv-sl24-c-sw",
            "eordcl-des-214elv-sl24-t-sw",
            "eordcl-des-215elv-sl25-c-sw",
            "eordcl-des-215elv-sl25-t-sw",
            "eordcl-des-311elv-pl16-c-sw",
            "eordcl-des-311elv-pl16-t-sw",
            "eordcl-des-311elv-pl17-c-sw",
            "eordcl-des-311elv-pl17-t-sw",
            "eordcl-des-311elv-pl18-c-sw",
            "eordcl-des-311elv-pl18-t-sw",
            "eordcl-des-311elv-pl19-c-sw",
            "eordcl-des-311elv-pl19-t-sw",
            "eordcl-des-312elv-pl20-c-sw",
            "eordcl-des-312elv-pl20-t-sw",
            "eordcl-des-312elv-pl22-c-sw",
            "eordcl-des-312elv-pl22-t-sw",
            "eordcl-des-313elv-pl21-c-sw",
            "eordcl-des-313elv-pl21-t-sw",
            "eordcl-des-313elv-pl23-c-sw",
            "eordcl-des-313elv-pl23-t-sw",
            "eordcl-des-412elv-pl15-c-sw",
            "eordcl-des-412elv-pl15-t-sw",
            "eordcl-des-412elv-sl13-c-sw",
            "eordcl-des-412elv-sl13-t-sw",
            "eordcl-des-412elv-sl14-c-sw",
            "eordcl-des-412elv-sl14-t-sw",
            "eordcl-des-512elv-pl09-c-sw",
            "eordcl-des-512elv-pl09-t-sw",
            "eordcl-des-512elv-pl10-c-sw",
            "eordcl-des-512elv-pl10-t-sw",
            "eordcl-des-512elv-pl11-c-sw",
            "eordcl-des-512elv-pl11-t-sw",
            "eordcl-des-512elv-pl12-c-sw",
            "eordcl-des-512elv-pl12-t-sw",
            "eordcl-des-515elv-pl05-c-sw",
            "eordcl-des-515elv-pl05-t-sw",
            "eordcl-des-515elv-pl06-c-sw",
            "eordcl-des-515elv-pl06-t-sw",
            "eordcl-des-515elv-pl07-c-sw",
            "eordcl-des-515elv-pl07-t-sw",
            "eordcl-des-515elv-pl08-c-sw",
            "eordcl-des-515elv-pl08-t-sw",
            "eordcl-des-613elv-sl04-c-sw",
            "eordcl-des-613elv-sl04-t-sw",
            "eordcl-des-615elv-sl03-c-sw",
            "eordcl-des-615elv-sl03-t-sw",
            "eordcl-des-704elv-sl01-c-sw",
            "eordcl-des-704elv-sl01-t-sw"
        )
    }
)

# Initialize counters
$processedCount = 0; $updatedCount = 0; $errorCount = 0

# Create parent group unless in dry-run mode
if (-not $dryRun) {
    $rootGroupId = New-SwisDynamicGroup -SwisConnection $swis -GroupName $rootGroup -Description "Auto-generated parent group" -RollupMode 0 -RefreshInterval 60 -PollingEnabled $true -Members @(@{ Name = "Cisco Devices"; Definition = "filter:/Orion.Nodes[Vendor='na']" })
}
else {
    Write-Log "  [DRY RUN] Would create group: $rootGroup" "INFO" "Magenta"
}

# Process each subgroup
foreach ($group in $subGroups) {
    $processedCount++
    $groupName = "$($group.GroupName) - $rootGroup"
    try {
        Write-Log "Processing group [$processedCount/$($subGroups.Count)]: $($group.GroupName)" "INFO" "Cyan"
        Write-Log "  Creating Group: $groupName" "INFO" "Yellow"

        if (-not $dryRun) {
            $subGroupMembers = @()
            foreach ($member in $group.Members) {
                $subGroupMembers += @{ Name = "Caption = $member"; Definition = "filter:/Orion.Nodes[Contains(Caption,'$member')]" }
            }
            $subGroupId = Add-SwisSubGroup -SwisConnection $swis -SubGroupName $groupName -ParentGroupId $rootGroupId -Members $subGroupMembers -Description "Auto-subgroup with filtered definitions" -PollingEnabled $true
            Write-Log "  Successfully created group '$groupName' with ID: $subGroupId" "INFO" "Green"
            $updatedCount++
        } else {
            Write-Log "  [DRY RUN] Would create group: $groupName" "INFO" "Magenta"
        }
    } catch {
        Write-Log "Error processing group $($group.GroupName) : $($_.Exception.Message)" "ERROR" "Red"
        $errorCount++
    }
}

# Summary output
Write-Log "============================================================================" "INFO" "Cyan"
Write-Log "EXECUTION SUMMARY" "INFO" "Cyan"
Write-Log "============================================================================" "INFO" "Cyan"
Write-Log "Total groups processed: $processedCount" "INFO" "White"
Write-Log "Groups created: $updatedCount" "INFO" "Green"
Write-Log "Errors encountered: $errorCount" "INFO" $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Log "Dry run mode: $dryRun" "INFO" "Yellow"
Write-Log "Log file: $logFile" "INFO" "White"
if ($dryRun) {
    Write-Log "This was a dry run. No actual changes were made." "INFO" "Yellow"
    Write-Log "To apply changes, set `$dryRun = `$false at the top of the script." "INFO" "Yellow"
}
Write-Log "Script execution completed" "INFO" "Cyan"
