<#
.SYNOPSIS
    Orion Server Certificate Management Script

.DESCRIPTION
    This script allows users to view and update SSL certificate settings for Orion servers
    by leveraging the SolarWinds Information Service (SWIS). It provides an interactive menu
    for users to:
        - View all Orion servers and their certificate settings
        - Update a server's certificate setting
        - Reset a server's certificate setting to default
        - Export certificate settings to a CSV file

.AUTHOR
    Ryan Woolsey

.VERSION
    1.1

.LICENSE
    This script is provided "as is" without any warranties. The author is not responsible
    for any damage or data loss caused by its use.

.NOTES
    Requires: PowerShell 5.1 or later, OrionSDK module
    
.LINK
    https://github.com/solarwinds/OrionSDK/wiki/PowerShell
#>

# Liability Clause
Write-Host "Disclaimer: Use this script at your own risk. The author is not responsible for any damage resulting from its use." -ForegroundColor Red

# Function: Connect to SolarWinds SWIS API
function Connect-SolarWinds {
    
    <#
    .SYNOPSIS
        Establishes a connection to the SolarWinds Information Service (SWIS).

    .DESCRIPTION
        Connects to a SolarWinds server using specified credentials and returns
        a connection object. If the connection fails, it will return null.

    .PARAMETER Hostname
        The hostname or IP address of the SolarWinds server.

    .PARAMETER Username
        The username used to authenticate the connection.

    .PARAMETER Password
        The password associated with the username.

    .EXAMPLE
        PS> Connect-SolarWinds -Hostname "solarwinds-server1" -Username "admin" -Password "password"
        Connects to the SolarWinds server using the given credentials.

    .EXAMPLE
        PS> $connection = Connect-SolarWinds -Hostname "10.0.0.1" -Username "loop1" -Password "P@ssw0rd"
        Stores the connection object in $connection.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, 
                   HelpMessage = "Enter the hostname or IP address of the SolarWinds server.")]
        [string]$Hostname,

        [Parameter(Mandatory = $true, 
                   HelpMessage = "Enter the username for authentication.")]
        [string]$Username,

        [Parameter(Mandatory = $true, 
                   HelpMessage = "Enter the password for the provided username.")]
        [string]$Password
    )

    # Build the connection parameters for SWIS
    $swisParams = @{
        Hostname = $Hostname
        UserName = $Username
        Password = $Password
        ErrorAction = 'Stop'  # Stops the function if an error occurs
    }

    # Attempt to connect to SWIS
    try {
        # The Connect-Swis cmdlet is used to establish a connection to the SolarWinds server
        return Connect-Swis @swisParams
    }
    catch {
        # If the connection fails, output an error message with the reason for the failure
        Write-Error "Failed to connect to SWIS: $_"
        return $null
    }
}

# Function: Retrieve Orion Servers and their Certificate Settings
function Get-OrionServersWithCertSettings {
    <#
    .SYNOPSIS
        Retrieves Orion servers and their certificate settings.

    .DESCRIPTION
        Queries the Orion database for all servers and their current SSL certificate settings.

    .PARAMETER SwisConnection
        The active SWIS connection.

    .PARAMETER OrionServerID
        (Optional) Filter results by a specific Orion server ID.

    .EXAMPLE
        PS> Get-OrionServersWithCertSettings -SwisConnection $conn
        Retrieves all Orion servers and their certificate settings.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$SwisConnection,
        
        [Parameter()]
        [int]$OrionServerID = 0
    )
    
    # Build WHERE clause if a specific server ID is provided
    $whereClause = ""
    if ($OrionServerID -gt 0) {
        $whereClause = "WHERE os.OrionServerID = $OrionServerID"
    }
    
    $query = @"
SELECT 
    os.OrionServerID,
    os.ServerType,
    os.HostName,
    s.DefaultValue AS SettingDefaultValue,
    so.Value AS SettingCurrentValue,
    os.Uri AS ServerURI,
    s.Uri AS SettingURI,
    so.Uri AS OverrideURI
FROM Orion.OrionServers os
LEFT JOIN Orion.Setting s 
    ON s.Name = 'Swis.RestEndpoint.CertificateNameForSafeguardCommunicationOnSwisRestEndpoint'
LEFT JOIN Orion.SettingOverride so 
    ON os.OrionServerID = so.OrionServerID 
    AND so.Name = 'Swis.RestEndpoint.CertificateNameForSafeguardCommunicationOnSwisRestEndpoint'
$whereClause
ORDER BY OrionServerID
"@

    try {
        $results = Get-SwisData -SwisConnection $SwisConnection -Query $query -ErrorAction Stop
        return $results
    }
    catch {
        Write-Error "Failed to retrieve Orion server data: $_"
        return $null
    }
}

# Function: Update or Create an Orion Setting Override
function Update-OrionCertificateSetting {
    <#
    .SYNOPSIS
        Updates the SSL certificate setting for a given Orion server.

    .DESCRIPTION
        Modifies the certificate name override for an Orion server.

    .PARAMETER SwisConnection
        The active SWIS connection.

    .PARAMETER ServerInfo
        The Orion server object containing certificate details.

    .PARAMETER NewCertName
        The new certificate name to assign.

    .EXAMPLE
        PS> Update-OrionCertificateSetting -SwisConnection $conn -ServerInfo $server -NewCertName "NewCert"
        Updates the certificate setting for the specified server.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$SwisConnection,
        
        [Parameter(Mandatory=$true)]
        [object]$ServerInfo,
        
        [Parameter(Mandatory=$true)]
        [string]$NewCertName
    )
    
    try {
        # Determine if we need to create or update an override
        if ($null -eq $ServerInfo.OverrideURI.Values -or $ServerInfo.OverrideURI.Values -eq "") {
            # Create new override
            $newOverride = @{
                "OrionServerID" = $ServerInfo.OrionServerID
                "Name" = "Swis.RestEndpoint.CertificateNameForSafeguardCommunicationOnSwisRestEndpoint"
                "Value" = $NewCertName
            }

            New-SwisObject -SwisConnection $SwisConnection -EntityType "Orion.SettingOverride" -Properties $newOverride
            Write-Host "Created new setting override for server '$($ServerInfo.HostName)'" -ForegroundColor Green
        }
        else {
            # Update existing override
            $updateProps = @{
                "Value" = $NewCertName
            }

            Set-SwisObject -SwisConnection $SwisConnection -Uri $ServerInfo.OverrideURI -Properties $updateProps
            Write-Host "Updated existing setting override for server '$($ServerInfo.HostName)'" -ForegroundColor Green
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to update certificate setting: $_"
        return $false
    }
}

# Function: Remove a Certificate Setting Override
function Remove-OrionSettingOverride {
    param (
        [Parameter(Mandatory = $true)]
        [object]$SwisConnection,

        [Parameter(Mandatory = $true)]
        [object]$ServerInfo
    )

    try {
        # Use the dynamic URI from the server info
        $URI = $ServerInfo.FullOverrideURI

        # If the URI is empty or null, construct it
        if ([string]::IsNullOrEmpty($URI)) {
            $URI = "swis://{0}/Orion/Orion.SettingOverride/Name=`"Swis.RestEndpoint.CertificateNameForSafeguardCommunicationOnSwisRestEndpoint`",OrionServerID={1}" -f $ServerName, $ServerInfo.OrionServerID
        }

        $result = Remove-SwisObject -SwisConnection $SwisConnection -Uri $URI

        Write-Host "Setting override removed successfully for server '$($ServerInfo.HostName)'!" -ForegroundColor Green
        return $result
    }
    catch {
        Write-Error "Error removing setting override: $_"
        return $false
    }
}

# Function: Format certificate values for display
function Format-CertificateValue {
    param([string]$Value)
    
    if ([string]::IsNullOrEmpty($Value)) {
        return "(Not Set)"
    }
    return $Value
}

function Show-Menu {
    param([string]$Title = "Orion Server Certificate Management")
    
    # Clear-Host
    Write-Host "================ $Title ================" -ForegroundColor Cyan
    Write-Host "1: View all servers and certificate settings"
    Write-Host "2: Update certificate setting for a server"
    Write-Host "3: Reset certificate setting to default (Remove Override)"
    Write-Host "4: Export certificate settings to CSV"
    Write-Host "Q: Quit"
    Write-Host "============================================" -ForegroundColor Cyan
}

function Get-SecureCredentials {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$UseDefault
    )

    if ($UseDefault) {
        # Use predefined credentials (not recommended for production)
        $Username = ''
        # Convert plain text password to secure string
        $SecurePassword = ConvertTo-SecureString '' -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
        return $Credential
    }
    else {
        # Prompt for credentials interactively
        return Get-Credential -Message "Enter credentials for SolarWinds server"
    }
}

# Main Script Execution
# --------------------

# Default connection parameters
$ServerName = '-'
if (-not [string]::IsNullOrEmpty($ServerName)){
    $ServerName = Read-Host "Enter the main pollers hostname."
}

# Offer options for credentials
Write-Host "Connecting to SolarWinds server: $ServerName" -ForegroundColor Yellow
$useDefaultCreds = Read-Host "Use default credentials? (Y/N, default is N)"

if ($useDefaultCreds -eq 'Y' -or $useDefaultCreds -eq 'y') {
    $creds = Get-SecureCredentials -UseDefault
    $SwisConnection = Connect-SolarWinds -Hostname $ServerName -Username $creds.UserName -Password $creds.GetNetworkCredential().Password
}
else {
    $creds = Get-SecureCredentials
    $SwisConnection = Connect-SolarWinds -Hostname $ServerName -Username $creds.UserName -Password $creds.GetNetworkCredential().Password
}

# Validate connection before proceeding
if ($null -eq $SwisConnection) {
    Write-Error "No valid SWIS connection found. Exiting script."
    exit
}

# Main menu loop
do {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    
    switch ($selection) {
        '1' {
            # View all servers and settings
            Write-Host "Retrieving all Orion servers and certificate settings..." -ForegroundColor Cyan
            $allServers = Get-OrionServersWithCertSettings -SwisConnection $SwisConnection
            
            if ($null -ne $allServers) {
                # Create a custom table with formatted values
                $allServers | ForEach-Object {
                    [PSCustomObject]@{
                        OrionServerID = $_.OrionServerID
                        HostName = $_.HostName
                        ServerType = $_.ServerType
                        DefaultValue = Format-CertificateValue $_.SettingDefaultValue
                        CurrentValue = Format-CertificateValue $_.SettingCurrentValue
                    }
                } | Format-Table -AutoSize
            }
            
            # View more information on a server or continue
            $response1 = Read-Host "Enter a Server ID to view more information or Press Enter to Continue"
            if($response1){
                Get-OrionServersWithCertSettings -SwisConnection $SwisConnection -OrionServerID $response1 | Format-List
            }
        }
        '2' {
            # Update a server's certificate setting
            Write-Host "Retrieving all Orion servers..." -ForegroundColor Cyan
            $allServers = Get-OrionServersWithCertSettings -SwisConnection $SwisConnection
            
            if ($null -ne $allServers) {
                $allServers | ForEach-Object {
                    [PSCustomObject]@{
                        OrionServerID = $_.OrionServerID
                        HostName = $_.HostName
                        ServerType = $_.ServerType
                        CurrentValue = Format-CertificateValue $_.SettingCurrentValue
                    }
                } | Format-Table -AutoSize
                
                $serverId = Read-Host "Enter the OrionServerID to update (or press Enter to cancel)"
                
                if (-not [string]::IsNullOrEmpty($serverId)) {
                    $serverInfo = $allServers | Where-Object { $_.OrionServerID -eq $serverId }
                    
                    if ($null -ne $serverInfo) {
                        # Show current certificate info
                        Write-Host "Server: $($serverInfo.HostName)" -ForegroundColor Cyan
                        Write-Host "Default Certificate: $(Format-CertificateValue $serverInfo.SettingDefaultValue)" -ForegroundColor Cyan
                        Write-Host "Current Certificate: $(Format-CertificateValue $serverInfo.SettingCurrentValue)" -ForegroundColor Cyan
                        
                        $newCertName = Read-Host "Enter the new certificate name (or press Enter to cancel)"
                        
                        if (-not [string]::IsNullOrEmpty($newCertName)) {
                            $updated = Update-OrionCertificateSetting -SwisConnection $SwisConnection -ServerInfo $serverInfo -NewCertName $newCertName
                            
                            if ($updated) {
                                # Show the updated information
                                $updatedServer = Get-OrionServersWithCertSettings -SwisConnection $SwisConnection -OrionServerID $serverId
                                
                                if ($null -ne $updatedServer) {
                                    Write-Host "Updated Certificate Settings:" -ForegroundColor Green
                                    [PSCustomObject]@{
                                        OrionServerID = $updatedServer.OrionServerID
                                        HostName = $updatedServer.HostName
                                        ServerType = $updatedServer.ServerType
                                        DefaultValue = Format-CertificateValue $updatedServer.SettingDefaultValue
                                        CurrentValue = Format-CertificateValue $updatedServer.SettingCurrentValue
                                    } | Format-Table -AutoSize
                                }
                            }
                        }
                        else {
                            Write-Host "Operation canceled" -ForegroundColor Yellow
                        }
                    }
                    else {
                        Write-Host "Server with ID $serverId not found" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "Operation canceled" -ForegroundColor Yellow
                }
            }
            
            Read-Host "Press Enter to continue"
        }
        '3' {
            # Reset a server's certificate setting to default
            Write-Host "Retrieving all Orion servers with custom certificate settings..." -ForegroundColor Cyan
            $allServers = Get-OrionServersWithCertSettings -SwisConnection $SwisConnection
            $serversWithOverrides = $allServers | Where-Object { -not [string]::IsNullOrEmpty($_.SettingCurrentValue) }
            
            if ($null -ne $serversWithOverrides -and $serversWithOverrides.Count -gt 0) {
                $serversWithOverrides | ForEach-Object {
                    [PSCustomObject]@{
                        OrionServerID = $_.OrionServerID
                        HostName = $_.HostName
                        ServerType = $_.ServerType
                        DefaultValue = Format-CertificateValue $_.SettingDefaultValue
                        CurrentValue = Format-CertificateValue $_.SettingCurrentValue
                    }
                } | Format-Table -AutoSize
                
                $serverId = Read-Host "Enter the OrionServerID to reset to default (or press Enter to cancel)"
                
                if (-not [string]::IsNullOrEmpty($serverId)) {
                    $serverInfo = $serversWithOverrides | Where-Object { $_.OrionServerID -eq $serverId }
                    
                    if ($null -ne $serverInfo) {
                        try {
                            # Delete the override
                            Remove-OrionSettingOverride -SwisConnection $SwisConnection -ServerInfo $serverInfo
                            
                            # Show the updated information
                            $updatedServer = Get-OrionServersWithCertSettings -SwisConnection $SwisConnection -OrionServerID $serverId
                            
                            if ($null -ne $updatedServer) {
                                Write-Host "Updated Certificate Settings:" -ForegroundColor Green
                                [PSCustomObject]@{
                                    OrionServerID = $updatedServer.OrionServerID
                                    HostName = $updatedServer.HostName
                                    ServerType = $updatedServer.ServerType
                                    DefaultValue = Format-CertificateValue $updatedServer.SettingDefaultValue
                                    CurrentValue = Format-CertificateValue $updatedServer.SettingCurrentValue
                                } | Format-Table -AutoSize
                            }
                        }
                        catch {
                            Write-Error "Failed to reset certificate setting: $_"
                        }
                    }
                    else {
                        Write-Host "Server with ID $serverId not found or does not have a custom setting" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "Operation canceled" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "No servers found with custom certificate settings" -ForegroundColor Yellow
            }
            
            Read-Host "Press Enter to continue"
        }
        '4' {
            # Export certificate settings to CSV
            Write-Host "Retrieving all Orion servers and certificate settings for export..." -ForegroundColor Cyan
            $allServers = Get-OrionServersWithCertSettings -SwisConnection $SwisConnection
            
            if ($null -ne $allServers) {
                # Create a custom array with formatted values for export
                $exportData = $allServers | ForEach-Object {
                    [PSCustomObject]@{
                        OrionServerID = $_.OrionServerID
                        HostName = $_.HostName
                        ServerType = $_.ServerType
                        DefaultCertificate = Format-CertificateValue $_.SettingDefaultValue
                        CurrentCertificate = Format-CertificateValue $_.SettingCurrentValue
                        HasOverride = if ([string]::IsNullOrEmpty($_.SettingCurrentValue)) { $false } else { $true }
                    }
                }
                
                # Get the export path
                $defaultPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\OrionCertificateSettings_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
                $exportPath = Read-Host "Enter the path to save the CSV file (default: $defaultPath)"
                
                if ([string]::IsNullOrEmpty($exportPath)) {
                    $exportPath = $defaultPath
                }
                
                try {
                    $exportData | Export-Csv -Path $exportPath -NoTypeInformation
                    Write-Host "Successfully exported certificate settings to: $exportPath" -ForegroundColor Green
                }
                catch {
                    Write-Error "Failed to export certificate settings: $_"
                }
            }
            else {
                Write-Host "No data available to export" -ForegroundColor Yellow
            }
            
            Read-Host "Press Enter to continue"
        }
    }
} until ($selection -eq 'Q' -or $selection -eq 'q')

Write-Host "Restart the SWInfoServiceSvcV3 service on the updated pollers to apply the changes." -ForegroundColor Red
Write-Host "Exiting script. Goodbye!" -ForegroundColor Cyan