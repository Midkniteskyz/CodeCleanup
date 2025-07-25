<#
.SYNOPSIS
    PowerShell script for FTP automation and management.

.DESCRIPTION
    This script facilitates automated FTP file transfers and manages FTP-related tasks. It includes functions for
    sending files to an FTP server, configuring Windows Firewall exceptions for FTP, adding necessary FTP features
    to Windows, creating an FTP site, and providing an interactive menu for easy navigation. The script is designed
    to simplify FTP operations, making it particularly useful for scenarios involving regular file transfers.

.NOTES
    File Name      : FTP_Automation.ps1
    Author         : Ryan Woolsey
    Prerequisite   : PowerShell

.LINK
    GitHub Repo    : https://github.com/Midkniteskyz/FTP_Automation/tree/main

.EXAMPLE
    .\FTP_Automation.ps1
    # Runs the script and presents the main menu for selecting FTP client or server tasks.

.EXAMPLE
    .\FTP_Automation.ps1 -TriggerFTP
    # Initiates automated FTP transfers without displaying the menu.

#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$TriggerFTP
)

# Function to send a file to the FTP Server
function Start-FTPFileTransfer {
    [CmdletBinding()]
    param(
        # Show default settings
        [switch]$ShowSettings,

        # FTP Server
        [Parameter(Mandatory = $false)]
        [string]$FTPServer,

        # FTP Username
        [Parameter(Mandatory = $false)]
        [string]$FTPUsername,

        # FTP Password
        [Parameter(Mandatory = $false)]
        [string]$FTPPassword,

        # File to upload
        [Parameter(Mandatory = $false)]
        [string]$FileToUpload
    )

    if ($ShowSettings) {
        Write-Host "FTP Server: $FTPServer`nUsername: $FTPUserName`nPassword: $FTPPassword`nFile to Upload: $FileToUpload"
        return
    }

    # Path to the file you want to upload
    $localFilePath = $FileToUpload

    # Remote directory where you want to upload the file
    $remoteDirectory = "/"

    # Combine FTP server URL and remote directory to form the full remote path
    $remoteUrl = "$ftpServer$remoteDirectory" + (Get-Item $localFilePath).Name

    # Create a credential object for FTP authentication
    $credentials = New-Object System.Net.NetworkCredential($ftpUsername, $ftpPassword)

    # Create the FTP WebRequest object
    $ftpWebRequest = [System.Net.WebRequest]::Create($remoteUrl)
    $ftpWebRequest.Credentials = $credentials
    $ftpWebRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile

    # Read the file into a byte array
    $fileContents = [System.IO.File]::ReadAllBytes($localFilePath)

    # Get the request stream and write the file contents to it
    $requestStream = $ftpWebRequest.GetRequestStream()
    $requestStream.Write($fileContents, 0, $fileContents.Length)
    $requestStream.Close()

    # Get the FTP server's response
    $response = $ftpWebRequest.GetResponse()

    # Close the response stream
    $response.Close()

    Remove-Item $localFilePath

}

# Function to create the scheduled task to run this script
function Import-FTPTask {

    <#
    .SYNOPSIS
        Creates and configures a scheduled task to run the FTP Transfer script.

    .DESCRIPTION
        This function creates and configures a scheduled task using the specified XML configuration. The task is designed
        to run the FTP Transfer script at a specified interval and with defined settings.

    .PARAMETER None
        This function does not accept any parameters.
    #>

    [CmdletBinding()]
    param ()

        # Display a message indicating the task configuration process
        Write-Host "Importing the XML configuration to the scheduled tasks."

        # XML configuration for the scheduled task
        $taskXml = @"
        <?xml version="1.0" encoding="UTF-16"?>
        <Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
          <!-- Task registration information -->
          <RegistrationInfo>
            <Date>2023-08-10T11:40:59.223005</Date>
            <Author>ISOLATED-FXFER1\Administrator</Author>
            <Description>Start the FTP Transfer script task</Description>
            <URI>\FTPTransfer</URI>
          </RegistrationInfo>
          <!-- Task triggers -->
          <Triggers>
            <BootTrigger>
              <Enabled>true</Enabled>
            </BootTrigger>
            <CalendarTrigger>
              <Repetition>
                <Interval>PT1M</Interval>
                <StopAtDurationEnd>false</StopAtDurationEnd>
              </Repetition>
              <StartBoundary>2023-08-10T00:00:00</StartBoundary>
              <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
              <Enabled>true</Enabled>
              <ScheduleByDay>
                <DaysInterval>1</DaysInterval>
              </ScheduleByDay>
            </CalendarTrigger>
          </Triggers>
          <!-- Task principals -->
          <Principals>
            <Principal id="Author">
              <UserId>S-1-5-18</UserId>
              <RunLevel>HighestAvailable</RunLevel>
            </Principal>
          </Principals>
          <!-- Task settings -->
          <Settings>
            <MultipleInstancesPolicy>Queue</MultipleInstancesPolicy>
            <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
            <!-- ... [Other settings] ... -->
          </Settings>
          <!-- Task actions -->
          <Actions Context="Author">
            <Exec>
              <Command>powershell.exe</Command>
              <Arguments>-executionpolicy bypass -File "C:\FTP\Scripts\Main.ps1" -TriggerFTP</Arguments>
            </Exec>
          </Actions>
        </Task>
"@

        # Register the scheduled task using the XML configuration
        Register-ScheduledTask -Xml $taskXml -TaskName "FTPTransfer"

        # Start the scheduled task
        Start-ScheduledTask -TaskName "FTPTransfer"
}

# Function to set the firewall for FTP on the client

function Set-FTPFireWallException {

    <#
    .SYNOPSIS
        Configures the firewall rules for FTP connections.
    
    .DESCRIPTION
        This function checks for the presence of FTP firewall rules and either creates new rules or enables
        existing rules to allow FTP connections. It uses the specified rule name and settings to configure
        the firewall for both UDP and TCP protocols on specified ports.
    
    .PARAMETER None
        This function does not accept any parameters.
    #>

    # Display a message indicating firewall configuration
    Write-Host "Configuring firewall for FTP."

    # Specify the rule name to identify FTP rules
    $ruleName = "File Transfer Program"

    # Check if a firewall rule with the specified rule name exists
    $firewallRule = Get-NetFirewallRule | Where-Object { $_.DisplayName -eq $ruleName }

    if ($firewallRule -eq $null) {
        # If no rule exists, create and enable new firewall rules for FTP
        Write-Warning "FTP rules not found. Creating and enabling the rule..."

        # Create UDP rule
        New-NetFirewallRule -DisplayName "$ruleName" -Description "$ruleName" -Enabled True -Profile Private, Public -Direction Inbound -Action Allow -Protocol UDP -LocalPort 20, 21, 49152-65535 -Program "%SystemRoot%\system32\ftp.exe" -Service Any -EdgeTraversalPolicy Allow

        # Create TCP rule
        New-NetFirewallRule -DisplayName "$ruleName" -Description "$ruleName" -Enabled True -Profile Private, Public -Direction Inbound -Action Allow -Protocol TCP -LocalPort 20, 21, 49152-65535 -Program "%SystemRoot%\system32\ftp.exe" -Service Any -EdgeTraversalPolicy Allow

        Write-Host "FTP rule created and enabled."
    }
    elseif ($firewallRule.Enabled -eq $false) {
        # If the rule exists but is disabled, enable it
        Write-Host "Enabling the existing FTP rule..."
        Set-NetFirewallRule -Name $ruleName -Enabled True
        Write-Host "FTP rule enabled."
    }
    else {
        # If the rule is already enabled, indicate that it's allowed and enabled
        Write-Host "FTP rule is already allowed and enabled."
    }

    # Display a message indicating completion of firewall configuration
    Write-Host "Firewall configuration completed."
}


# Function to add required Windows features for FTP on the server
function Add-WindowsFTPFeatures {
    <#
    .SYNOPSIS
        Checks and installs required Windows features for setting up an FTP server.

    .DESCRIPTION
        This function checks for the presence of required Windows features for setting up an FTP server.
        If the features are not installed, it installs them. This function is useful for ensuring that
        the necessary components are available before creating the FTP server.

    .PARAMETER None
        This function does not accept any parameters.
    #>

    # Display a message indicating feature check
    Write-Host "Checking if required FTP features are installed."

    # Check if Windows Server FTP Server feature is installed
    $ftpFeature = Get-WindowsFeature | Where-Object { $_.Name -eq "Web-Ftp-Server" }
    if (!($ftpFeature.Installed)) {
        Write-Host "Windows Server FTP Server feature is not installed. Installing now..."
        Install-WindowsFeature -Name "Web-Ftp-Server" -IncludeAllSubFeature
    }
    else {
        Write-Host "Windows Server FTP Server feature is installed."
    }

    # Check if FTP Extensibility feature is installed
    $ftpExtFeature = Get-WindowsFeature | Where-Object { $_.Name -eq "Web-Ftp-Ext" }
    if (!($ftpExtFeature.installed)) {
        Write-Host "FTP Extensibility feature is not installed. Installing now..."
        Install-WindowsFeature -Name "Web-Ftp-Ext"
    }
    else {
        Write-Host "FTP Extensibility feature is installed."
    }

    # Check if IIS Manager is installed
    $iisManagerFeature = Get-WindowsFeature | Where-Object { $_.Name -eq "Web-Mgmt-Console" }
    if (!($iisManagerFeature.Installed)) {
        Write-Host "IIS Manager is not installed. Installing now..."
        Install-WindowsFeature -Name "Web-Mgmt-Console"
    }
    else {
        Write-Host "IIS Manager is installed."
    }

    # Check if IIS Scripts and Tools is installed
    $iisScriptsFeature = Get-WindowsFeature | Where-Object { $_.Name -eq "Web-Scripting-Tools" }
    if (!($iisScriptsFeature.Installed)) {
        Write-Host "IIS Scripts and Tools is not installed. Installing now..."
        Install-WindowsFeature -Name "Web-Scripting-Tools"
    }
    else {
        Write-Host "IIS Scripts and Tools is installed."
    }

    # Display a message indicating completion of feature checks
    Write-Host "Windows feature checks complete."
}


# Function to create the FTP site
function New-FtpSite {

    <#
    .SYNOPSIS
        Creates and configures a new FTP site in IIS.

    .DESCRIPTION
        This function creates and configures a new FTP site in IIS. It allows specifying the site name, physical path,
        and port for the FTP site. The function also sets up anonymous authentication, SSL policy, and authorization
        settings for allowing read and write access for anonymous users.

    .PARAMETER ftpSiteName
        Specifies the name of the FTP site to be created. Default is 'FendFTP'.

    .PARAMETER ftpPhysicalPath
        Specifies the physical path where the FTP files will be stored. Default is 'C:\FendFTPInbound'.

    .PARAMETER ftpPort
        Specifies the port number for the FTP site. Default is 21.

    .NOTES
        Prerequisite   : PowerShell, WebAdministration module
    #>

    [CmdletBinding()]
    param (
        [string]$ftpSiteName = 'FendFTP',
        [string]$ftpPhysicalPath = 'C:\FendFTPInbound',
        [string]$ftpPort = 21
    )

    # Display a message indicating site creation
    Write-Host "Creating the FTP site and FTP path."

    # Import the WebAdministration module if not already imported
    Import-Module WebAdministration

    # Create the FTP directory if it doesn't exist
    if (!(Test-Path $ftpPhysicalPath)) {
        Write-Host "FTP Directory not found. Creating $ftpPhysicalPath"
        New-Item -ItemType Directory -Path $ftpPhysicalPath
    }
    else {
        Write-Host "FTP directory exists"
    }

    # Create the new FTP site
    New-WebFtpSite -Name $ftpSiteName -Port $ftpPort -PhysicalPath $ftpPhysicalPath -Force

    # Set the site's physical path
    Set-ItemProperty "IIS:\Sites\$ftpSiteName" -Name physicalPath -Value $ftpPhysicalPath

    # Enable anonymous authentication
    $ftpSitePath = "IIS:\Sites\$ftpSiteName"
    $anonAuth = 'ftpServer.security.authentication.anonymousAuthentication.enabled'
    Set-ItemProperty -Path $ftpSitePath -Name $anonAuth -Value $True

    # Set SSL policy for the FTP site
    Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.applicationHost/sites/site[@name='$ftpSiteName']/ftpServer/security/ssl" -Name "controlChannelPolicy" -Value "SslAllow"
    Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.applicationHost/sites/site[@name='$ftpSiteName']/ftpServer/security/ssl" -Name "dataChannelPolicy" -Value "SslAllow"

    # Allow anonymous users to read and write
    $param = @{
        Filter   = "/system.ftpServer/security/authorization"
        Value    = @{
            accesstype  = "Allow"
            roles       = ""
            permissions = "Read,Write"
            users       = "*"
        }
        PSPath   = 'IIS:\'
        Location = $ftpSiteName
    }

    Add-WebConfiguration @param

    # Restart the FTP site for the changes to take effect
    Restart-WebItem "IIS:\Sites\$ftpSiteName" -Verbose

    # Display a message indicating successful site creation and configuration
    Write-Host "FTP Site has been created and configured."
}

#region Menu Functions

function MainMenu {

    <#
    .SYNOPSIS
        Displays the main menu of the PowerShell script.

    .DESCRIPTION
        This function displays a main menu for the PowerShell script. It presents options for FTP Client, FTP Server, or quitting the script.
    #>

    Clear-Host
    Write-Host "Welcome to the PowerShell Menu!"

    Write-Host "What're you working on?"
    Write-Host "    1) FTP Client"
    Write-Host "    2) FTP Server"
    Write-Host "    q) Quit"

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            ClientMenu
        }
        "2" {
            ServerMenu
        }
        "q" {
            return
        }
        default {
            Write-Host "Invalid choice. Please select a valid option."
            MainMenu
        }
    }
}

function ClientMenu {

    <#
    .SYNOPSIS
        Displays the FTP Client menu.

    .DESCRIPTION
        This function displays the FTP Client menu, allowing the user to choose between automatic setup, custom tasks, or going back to the main menu.
    #>

    Clear-Host
    Write-Host "FTP Client Menu"

    Write-Host "Pick an option"
    Write-Host "    1) Automatic Set-Up"
    Write-Host "    2) Custom Tasks"
    Write-Host "    q) Back"

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            # Code for automatic setup

            pause

        }
        "2" {
            CustomTasksMenu
        }
        "q" {
            MainMenu
        }
        default {
            Write-Host "Invalid choice. Please select a valid option."
            ClientMenu
        }
    }
}

function CustomTasksMenu {

    <#
    .SYNOPSIS
        Displays the Custom Tasks menu for the FTP Client.

    .DESCRIPTION
        This function displays the Custom Tasks menu for the FTP Client, allowing the user to choose various custom tasks related to the FTP client operations.
    #>

    Clear-Host
    Write-Host "Custom Tasks Menu"

    Write-Host "    1) Configure Client Firewall"
    Write-Host "    2) Manually upload file to FTP Server"
    Write-Host "    3) Manually upload directory to FTP Server"
    Write-Host "    4) Import Scheduled Task"
    Write-Host "    q) Back"

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            # Code to configure client firewall

            pause

            CustomTasksMenu
        }
        "2" {
            # Code to manually upload file to FTP Server

            pause

            CustomTasksMenu
        }
        "3" {
            # Code to manually upload directory to FTP Server

            pause

            CustomTasksMenu
        }
        "4" {
            # Code to import scheduled task

            pause

            CustomTasksMenu
        }
        "q" {
            ClientMenu
        }
        default {
            Write-Host "Invalid choice. Please select a valid option."
            CustomTasksMenu
        }
    }
}

function ServerMenu {

    <#
    .SYNOPSIS
        Displays the FTP Server menu.

    .DESCRIPTION
        This function displays the FTP Server menu, allowing the user to choose between automatic setup, adding Windows FTP features, creating an FTP site, or going back to the main menu.
    #>

    Clear-Host
    Write-Host "FTP Server Menu"

    Write-Host "    1) Automatic Set-Up"
    Write-Host "    2) Add Windows FTP Features"
    Write-Host "    3) Create FTP Site"
    Write-Host "    q) Back"

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            # Code for automatic setup

            pause

            Write-Host "Windows needs to reboot."
            Pause

            Restart-Computer -Force

        }
        "2" {
            # Code to add Windows FTP features

            Pause

            ServerMenu
        }
        "3" {
            # Code to create FTP site

            Pause

            ServerMenu
        }
        "q" {
            MainMenu
        }
        default {
            Write-Host "Invalid choice. Please select a valid option."
            ServerMenu
        }
    }
}

#endregion Menu Functions

# Check if the script was triggered with the FTP flag
if ($TriggerFTP) {
    # If the FTP flag is set, trigger the FTP send without displaying the main menu

    # Get a list of files in the "Outbound" directory
    $directory = Get-ChildItem "C:\FTP\Outbound"

    # Loop through each file and start the FTP file transfer
    foreach ($d in $directory) {
        Start-FTPFileTransfer -FTPServer "ftp://<IPADDRESS>" -FTPUsername "anonymous" -FTPPassword  "<PASSWORD>" -FileToUpload ($d.FullName)

        # Pause for 5 seconds between transfers
        Start-Sleep 5
    }
}
else {
    # If the FTP flag is not set, start the main menu to allow user interaction

    # Start the main menu function
    MainMenu
}
