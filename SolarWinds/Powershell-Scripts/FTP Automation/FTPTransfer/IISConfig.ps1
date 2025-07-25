# Import the WebAdministration module if not already imported
Import-Module WebAdministration

# Create the new FTP site
$ftpSiteName = 'FTPDest'
$ftpPhysicalPath = 'C:\FTP'
$ftpPort = 21

# Create the FTP dirctory
if(!(test-path $ftpPhysicalPath)){
    Write-Host "FTP Directory not found. Creating $ftpPhysicalPath"
    New-Item -ItemType Directory -Name "FTP" -Path "C:\"
}else{
    Write-Host "FTP directory exists"
}

New-WebFtpSite -Name $ftpSiteName -Port $ftpPort -PhysicalPath $ftpPhysicalPath

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