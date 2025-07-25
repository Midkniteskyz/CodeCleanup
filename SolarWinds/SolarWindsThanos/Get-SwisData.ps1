function Connect-SolarWinds {
    
    <#
    .SYNOPSIS
        Connects to the SolarWinds Information Service (SWIS) using specified credentials.
    
    .DESCRIPTION
        This function establishes a connection to the SolarWinds Information Service (SWIS) on a given SolarWinds server. 
        The function takes the hostname of the server, a username, and a password as input parameters. If the connection fails, 
        it will throw an error and return null.
    
    .PARAMETER Hostname
        The hostname or IP address of the SolarWinds server.
    
    .PARAMETER Username
        The username used to authenticate the connection to the SolarWinds server.
    
    .PARAMETER Password
        The password associated with the provided username for authentication.
    
    .EXAMPLE
        PS> Connect-SolarWinds -Hostname "solarwinds-server1" -Username "admin" -Password "password"
    
        Connects to the SolarWinds server 'solarwinds-server1' using the credentials 'admin' and 'password'.
    
    .EXAMPLE
        PS> $connection = Connect-SolarWinds -Hostname "10.0.0.1" -Username "loop1" -Password "P@ssw0rd"
    
        Stores the connection object to the SolarWinds server '10.0.0.1' in the variable $connection.
    
    .NOTES
        Author: Ryan Woolsey
        Last Edit: 9-20-2024
        Version: 1.1
        Keywords: SolarWinds, OrionSDK, PowerShell, SWIS
    
    .LINK
        https://github.com/solarwinds/OrionSDK/wiki/PowerShell
    
    .REQUIRES
        # Requires -Version 5.1
        # Requires -Modules OrionSDK
    
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

$Username = 'L1SENG\RWoolsey'
$Password = 'W@shingt0n22!'
$MPE = 'hco.loop1.ziti'

$swis = Connect-SolarWinds -Hostname $MPE -Username $Username -Password $Password

Get-SwisObject $swis -Uri 'swis://L1SENGHCO.l1seng.com/Orion/Metadata.Entity/FullName="Orion.ContainerMemberDefinition"/Verbs/Name="GetMembers"/Arguments/Position=0' | fl


Get-SwisObject $swis -Uri 'swis://localhost/Orion/Orion.Nodes/NodeID=1/CustomProperties'

$results = Get-SwisObject $swis -Uri 'swis://localhost/Orion/Metadata.Entity/FullName=Cirrus.GlobalSettings'

#$results = Get-SwisObject $swis -Uri 'swis://localhost/Orion/Metadata.Entity/FullName="Cirrus.Settings"/Properties/Name="DisplayName"' 
# https://hco.loop1.ziti/Orion/NCM/Admin/Settings/ConfigSettings.aspx

swis://L1SENGHCO.l1seng.com/Orion/Metadata.Entity/FullName="Cirrus.Settings"

$path = ''
$networkShareUserName = ''
$networkSharePassword = ''

@($path, $networkShareUserName, $networkSharePassword)

$results = Invoke-SwisVerb $swis 'Cirrus.Nodes' 'GetConnectionProfile' @('2')

$results = Invoke-SwisVerb $swis 'Cirrus.Nodes' 'GetAllConnectionProfiles' @()






