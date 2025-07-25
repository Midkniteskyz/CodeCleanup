
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

    if ($ShowSettings){
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

# Function to create a scheduled task to run this script
function Import-FTPTask{  
    Write-Host "Importing the XML configuration to the scheduled tasks."

    Register-ScheduledTask -xml `
            '<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2023-08-10T11:40:59.223005</Date>
    <Author>ISOLATED-FXFER1\Administrator</Author>
    <Description>Start the FTP Transfer script task</Description>
    <URI>\FTPTransfer</URI>
  </RegistrationInfo>
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
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>Queue</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
    <Priority>7</Priority>
    <RestartOnFailure>
      <Interval>PT1M</Interval>
      <Count>3</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-executionpolicy bypass -File "C:\FTP\Scripts\Main.ps1" -TriggerFTP</Arguments>
    </Exec>
  </Actions>
</Task>' `
            -TaskName "FTPTransfer"

            Start-ScheduledTask -TaskName "FTPTransfer"
}

# Function to set the firewall for FTP on the client
function Set-FTPFireWallException {
    Write-Host "Configuring firewall for FTP."

    $ruleName = "File Transfer Program"
    $firewallRule = Get-NetFirewallRule | Where-Object { $_.DisplayName -eq $ruleName }

    if ($firewallRule -eq $null) {
        Write-Warning "FTP rules not found. Creating and enabling the rule..."
        New-NetFirewallRule -DisplayName "$ruleName" -Description "$rulename" -Enabled True -Profile Private, Public -Direction Inbound -Action Allow -Protocol UDP -LocalPort 20,21,49152-65535 -Program "%SystemRoot%\system32\ftp.exe" -Service Any -EdgeTraversalPolicy Allow
        New-NetFirewallRule -DisplayName "$ruleName" -Description "$rulename" -Enabled True -Profile Private, Public -Direction Inbound -Action Allow -Protocol TCP -LocalPort 20,21,49152-65535 -Program "%SystemRoot%\system32\ftp.exe" -Service Any -EdgeTraversalPolicy Allow
        Write-Host "FTP rule created and enabled."
    }
    elseif ($firewallRule.Enabled -eq $false) {
        Write-Host "Enabling the existing FTP rule..."
        Set-NetFirewallRule -Name $ruleName -Enabled True
        Write-Host "FTP rule enabled."
    }
    else {
        Write-Host "FTP rule is already allowed and enabled."
    }

    Write-Host "Firewall configuration conpleted."
}

# Function to add the required FTP features in Windows
function Add-WindowsFTPFeatures {
    Write-Host "Checking if required FTP features are installed."

    # Check if Windows Server FTP Server feature is installed
    $ftpFeature = Get-WindowsFeature | Where-Object { $_.Name -eq "Web-Ftp-Server" }
    if (!($ftpFeature.Installed)) {
        Write-Host "Windows Server FTP Server feature is not installed. Installing now..."
        Install-WindowsFeature -Name "Web-Ftp-Server" -IncludeAllSubFeature
    } else {
        Write-Host "Windows Server FTP Server feature is installed."
    }

    # Check if FTP Extensibility feature is installed
    $ftpExtFeature = Get-WindowsFeature | Where-Object { $_.Name -eq "Web-Ftp-Ext" }
    if (!($ftpExtFeature.installed)) {
        Write-Host "FTP Extensibility feature is not installed. Installing now..."
        Install-WindowsFeature -Name "Web-Ftp-Ext"
    } else {
        Write-Host "FTP Extensibility feature is installed."
    }

    # Check if IIS Manager is installed
    $iisManagerFeature = Get-WindowsFeature | Where-Object { $_.Name -eq "Web-Mgmt-Console" }
    if (!($iisManagerFeature.Installed)) {
        Write-Host "IIS Manager is not installed. Installing now..."
        Install-WindowsFeature -Name "Web-Mgmt-Console"
    } else {
        Write-Host "IIS Manager is installed."
    }

    # Check if IIS Scripts and Tools is installed
    $iisScriptsFeature = Get-WindowsFeature | Where-Object { $_.Name -eq "Web-Scripting-Tools" }
    if (!($iisScriptsFeature.Installed)) {
        Write-Host "IIS Scripts and Tools is not installed. Installing now..."
        Install-WindowsFeature -Name "Web-Scripting-Tools"
    } else {
        Write-Host "IIS Scripts and Tools is installed."
    }

    Write-Host "Windows feature checks complete."
}

# Function to create the FTP site
function New-FtpSite {
    [CmdletBinding()]
    param (
        [string]$ftpSiteName = 'FendFTP',
        [string]$ftpPhysicalPath = 'C:\FendFTPInbound',
        [string]$ftpPort = 21

        # TODO Add remove FTP Site switch
    )

    Write-Host "Creating the FTP site and FTP path."

    # Import the WebAdministration module if not already imported
    Import-Module WebAdministration

    # Create the FTP dirctory
    if(!(test-path $ftpPhysicalPath)){
        Write-Host "FTP Directory not found. Creating $ftpPhysicalPath"
        New-Item -ItemType Directory -Path $ftpPhysicalPath
    }else{
        Write-Host "FTP directory exists"
    }

    New-WebFtpSite -Name $ftpSiteName -Port $ftpPort -PhysicalPath $ftpPhysicalPath -force

    # Set the site path
    Set-ItemProperty "IIS:\Sites\$ftpsitename" -name physicalPath -value $ftpPhysicalPath

    # enable anonymous authentication 
    $ftpSitePath = "IIS:\Sites\$ftpsitename"
    $anonAuth = 'ftpServer.security.authentication.anonymousAuthentication.enabled'

    Set-ItemProperty -Path $ftpSitePath -Name $anonAuth -Value $True

    # Set SSL Policy
    Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.applicationHost/sites/site[@name='$ftpSiteName']/ftpServer/security/ssl" -Name "controlChannelPolicy" -Value "SslAllow"
    Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.applicationHost/sites/site[@name='$ftpSiteName']/ftpServer/security/ssl" -Name "dataChannelPolicy" -Value "SslAllow"


    # Allow anonymous users to read and write
    $Param = @{
        Filter = "/system.ftpServer/security/authorization"
        Value = @{
            accesstype = "Allow"
            roles = ""
            permissions = "Read,Write"
            users = "*"
        }
        PSPath = 'IIS:\'
        Location = $ftpSiteName
    }

    Add-WebConfiguration @param

    #Add-WebConfiguration "/system.ftpserver/security/authorization" -value @{accesstype = "Allow";roles = "";permissions = "Read,Write";users = "*"} -PSPath IIS:\ -Location "$sitename"

    #Restart site
    Restart-WebItem "IIS:\Sites\$ftpSiteName" -verbose

    Write-Host "FTP Site has been created and configured."
}


#region Menu Functions

function MainMenu {
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
    Clear-Host
    Write-Host "FTP Client Menu"
    
    Write-Host "Pick an option"
    Write-Host "    1) Automatic Set-Up"
    Write-Host "    2) Custom Tasks"
    Write-Host "    q) Back"
    
    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            # Create folder paths
            $FTPpaths = @(
            'C:\FTP'
            'C:\FTP\Logs',
            'C:\FTP\Outbound',
            'C:\FTP\Scripts'
            )

            foreach($f in $FTPpaths){
                if(!(Test-Path $f)){
                    Write-Host "'$f' not found. Creating directory now." 
                    New-Item -Path $f -ItemType dir
                }
            }

            $scriptpath = "$Env:userprofile\desktop\main.ps1"
            $copypath = "C:\FTP\Scripts\Main.ps1"

            Copy-Item -Path $scriptpath -Destination $copypath

            #Configure the firewall
            Set-FTPFireWallException

            # Create the scheduled task
            Import-FTPTask

            Start-ScheduledTask -TaskName "FTPTransfer"

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
            #Check if the firewall is open
            Set-FTPFireWallException

            pause

            CustomTasksMenu
        }
        "2" {

            # User prompts
            $FTPServer = "ftp://" + (Read-Host 'Enter the destination ip')
            $FTPUsername = Read-Host "Enter the FTP Username" 
            $FTPPassword  = Read-Host "Enter the FTP Password" 
            $FileToUpload = Read-Host "Enter the full path with the file name or enter 'q' to go back"

            if(!(Test-Path $FileToUpload)){
                Write-warning "File not found."
                $FileToUpload
            }else{
                Write-Host "Confirm settings`nFTP Server IP: $Ftpserver`nFTP UserName: $ftpusername`nFTP Password: $Ftppassword`nFile to upload: $filetoupload"



                $starttransfer = Read-Host "Enter 'y' to continue or 'n' to restart"

                if($starttransfer -ne 'y' -and $starttransfer -ne 'n'){
                    "Not an option"
                    $starttransfer
                }elseif($starttransfer -eq 'n'){
                    customtasksmenu
                }else{
                # Send a single file via FTP
                Start-FTPFileTransfer -FTPServer $FTPServer -FTPUsername $FTPUsername -FTPPassword $FTPPassword -FileToUpload $FileToUpload

                pause

                CustomTasksMenu
                }

            }


        }
        "3" {

            # Send all file in a directory manually
            $directoryinput = Read-Host "Enter a directory"
            $directory = Get-ChildItem $directoryinput
            
            foreach($d in $directory){
                Start-FTPFileTransfer -FTPServer "ftp://192.168.4.31" -FTPUsername "anonymous" -FTPPassword  "Test2023!" -FileToUpload ($d.FullName)

                sleep 5
            }

            pause

            CustomTasksMenu
        }
         "4" {

            Import-FTPTask

            Start-ScheduledTask -TaskName "FTPTransfer"

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
    Clear-Host
    Write-Host "FTP Server Menu"

    Write-Host "    1) Automatic Set-Up"
    Write-Host "    2) Add Windows FTP Features"
    Write-Host "    3) Create FTP Site"
    Write-Host "    q) Back"

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            Add-WindowsFTPFeatures;

            New-ftpsite

            pause

            Write-Host "Windows needs to reboot."
            Pause

            Restart-Computer -force

        }
        "2" {
            Add-WindowsFTPFeatures

            Pause

            ServerMenu
        }
        "3" {
            New-FtpSite

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


if ($TriggerFTP) {
    # trigger the FTP send without the menu
    
    $directory = Get-ChildItem "C:\FTP\Outbound"
            
    foreach($d in $directory){
        Start-FTPFileTransfer -FTPServer "ftp://192.168.4.31" -FTPUsername "anonymous" -FTPPassword  "Test2023!" -FileToUpload ($d.FullName)

        sleep 5
           }
}else {
    # Start the main menu
    MainMenu
}

s