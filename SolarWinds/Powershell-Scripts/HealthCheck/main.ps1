####### Startup #######
#please use a powershell integrated console to run script
# Watch for user to put "-configure" after the script in case config entry is needed
[cmdletbinding()]
param(
    [switch]$configure
)

####### Global Variables ######
$configFileName = "\config.json"
$scriptDir = Split-Path -parent $PSCommandPath
$configFullPath = $scriptDir + $configFileName
$WordFilePath = "C:\Users\Janine.Parham\OneDrive - Loop1\Desktop\projects\internal\HCScript\New-Document.docx"
$logPath = "C:\Users\Janine.Parham\OneDrive - Loop1\Desktop\projects\internal\HCScript"

###### Functions ######
# Function to set the config file, if needed
function Set-ConfigurationFile ($configFileName) {
    #remove any existing config file if needed
    try {
        Remove-item $configFullPath
    }
    catch {
        #no file to remove, just continue
    }
    #prompt user for hostname of Orion server
    $orionHost = read-host -prompt "Orion Server IP/Hostname"
    #prompt user for a username
    $userName = read-host -prompt "Orion Username"
    #prompt user for a password
    $pwdInput = read-host -prompt "Orion Password" -AsSecureString
    #convert from a PS Secure String object into encrypted string for storage
    $pwdEncStr = ConvertFrom-SecureString $pwdInput
    # Build a config object to store as JSON config file
    $configObj = [PSCustomObject]@{
        Orion = @{
            orionHost = $orionHost
            orionUser = $userName
            orionPw   = $pwdEncStr
        }
    }
    # Write the config file
    ConvertTo-Json -InputObject $configObj -depth 100 | out-file $configFullPath
}

#Main function for all Orion queries
function Get-Results($query){
    $results = Get-SwisData $swis -Query $query
    try{
        $results = Get-SwisData $swis -Query $query -ErrorAction Stop
    }
    catch{
        $message = "There was an error executing '"+$query+"': $($PSItem.ToString())"
        Write-L1Log -message $message
        return $null
    }
    return $results
}

$testMode = $false
function Write-L1Log (){
    param(
        [Parameter()]
        [string]$message,
        [Parameter()]
        [string]$severity = 'Information'
        #default value
    )
    if ($testMode -eq $true) {
        Write-Host $message
    } else {
        #debug
        $timeStamp = Get-Date
        $messageText = "$($timeStamp)`t$($Message)"
        # get the current date NUMBER in STRING format for unique filename
        # add/remove time formatting to create new file names on that unit
        # this example is hourly -Format "yyyyMMddHH"
        [string]$dateNBR = (Get-Date -Format "yyyy-MM-dd")
        # build the full path file name
        $logFileName = "\$($dateNBR).log"
        $logFullPath = $logPath + $logFileName
        #check if the Directory exists 
        #create if missing or add-content will fail
        if (Test-Path -Path $logPath){
            #the path exists
            #write/append to the file
            #the file will be created if it doesn't exist
            Add-Content -Path $logFullPath -Value $messageText
        }else{
            #we need to go back up a level to create the new dir
            $newFolder = $logPath.replace("\log", "")
            new-item -Path $newFolder -Name "log" -ItemType "directory"
            #Enter a first entry when the log dir is made
            $firstTimeStamp = (Get-Date -Format "yyyy-MM-dd HH:mm")
            $firstMessageText = "the Log directory was created."
            Add-Content -Path $logFullPath -Value "$($firstTimeStamp)`t$($firstMessageText)"
            #write/append to the file with original message passed to the function
            Add-Content -Path $logFullPath -Value $messageText
        }
        # clean up check point
        # delete any log files > 30 days old
        #$oldLogs = $logPath | Get-ChildItem | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30) -and $_.}
        if($oldLogs.Count -gt 1){
            # \Log it  > Use this block format to submit log entries
            $logMessage += "`tDeleting old log files: "
            $logMessage += $oldLogs
            Add-Content -Path $logFullPath -Value $logMessage
            # /Log it
            $oldLogs | remove-item
        }
    }
}

####### Connect to Orion #######
# Make sure SWIS module is installed and load it.
if (!(Get-InstalledModule | Where-Object { $_.Name -eq "SwisPowerShell" })) {
    try { Import-Module SwisPowerShell }
    catch {
        Write-Host "[FATAL] Failed to import SwisPowerShell Module."
        Write-Host "Ensure OrionSDK is installed and try running this script again as an administrator"
    }
}
# If user sets the config flag or if the config file is missing, trigger the config file builder
if (($configure) -or (!(Test-Path $configFullPath))) {
    Set-ConfigurationFile $configFileName

}
# We should now have a config file no matter what. Retrieve its data.
$configJSON = Get-Content $configFullPath
$config = $configJSON | ConvertFrom-Json
$orionHost = $config.Orion.orionHost
$orionUser = $config.Orion.orionUser
$orionPwdFromConfig = $config.Orion.orionPw
#Convert password to Secure String so we can build a creds object with it
$pwdSecStr = ConvertTo-SecureString $orionPwdFromConfig
# Build the credential object from the config file
[pscredential]$creds = New-Object System.Management.Automation.PSCredential ($orionUser, $pwdSecStr)
# Connect to Swis
$swis = Connect-Swis -Credential $creds -Hostname $orionHost  # create a SWIS connection object
# Can uncomment this to test that SWIS is behaving.
# $result = Get-SwisData $swis 'SELECT TOP 2 NodeID, Caption FROM Orion.Nodes'
# $result[0].Caption.GetType()
## Get-SwisData $swis  'SELECT NodeID ,Caption FROM Orion.Nodes Where Caption = @Caption' @{Caption = "L1SENGOrion"}

####### Verify Installed Modules #######
#Make modules hashtable
$modules = [ordered]@{}
#Add each module and whether they're installed into the modules hashtable
#1 module installed, 0 module not installed
[void]$modules.Add("Orion Servers", 1)
[void]$modules.Add("Orion Polling", 1)
[void]$modules.Add("Orion Core", 1)
$isNPM = Get-Results("SELECT count(*) as installed FROM Orion.InstalledModule WHERE Name='NPM'")
[void]$modules.Add("NPM", $isNPM)
$isSAM = Get-Results("SELECT count(*) as installed FROM Orion.InstalledModule WHERE Name='APM'")
[void]$modules.Add("SAM", $isSAM)
$isNCM = Get-Results("SELECT count(*) as installed FROM Orion.InstalledModule WHERE Name='NCM'")
[void]$modules.Add("NCM", $isNCM)
$isIPAM = Get-Results("SELECT count(*) as installed FROM Orion.InstalledModule WHERE Name='IPAM'")
[void]$modules.Add("IPAM", $isIPAM)
$isUDT = Get-Results("SELECT count(*) as installed FROM Orion.InstalledModule WHERE Name='UDT'")
[void]$modules.Add("UDT", $isUDT)
$isVNQM = Get-Results("SELECT count(*) as installed FROM Orion.InstalledModule WHERE Name='VoIP'")
[void]$modules.Add("VNQM", $isVNQM)
$isWPM = Get-Results("SELECT count(*) as installed FROM Orion.InstalledModule WHERE Name='SEUM'")
[void]$modules.Add("WPM", $isWPM)
$isNTA = Get-Results("SELECT count(*) as installed FROM Orion.InstalledModule WHERE Name='NTA'")
[void]$modules.Add("NTA", $isNTA)
$isVIM = Get-Results("SELECT count(*) as installed FROM Orion.InstalledModule WHERE Name='VIM'")
[void]$modules.Add("VIM", $isVIM)
$isOLM = Get-Results("SELECT count(*) as installed FROM Orion.InstalledModule WHERE Name='OLM'")
[void]$modules.Add("OLM", $isOLM)
$isSCM = Get-Results("SELECT count(*) as installed FROM Orion.InstalledModule WHERE Name='SCM'")
[void]$modules.Add("SCM", $isSCM)
$isSRM = Get-Results("SELECT count(*) as installed FROM Orion.InstalledModule WHERE Name='SRM'")
[void]$modules.Add("SRM", $isSRM)

####### Manage Microsoft Word #######
#Make sure PSWriteWord is installed
if (!(Get-InstalledModule | Where-Object { $_.Name -eq "PSWriteWord" })) {
    try { Import-Module PSWriteWord }
    catch {
        Write-Host "[FATAL] Failed to import PSWriteWord Module."
        Write-Host "Try running this script again as an administrator"
    }
}
#Make a new word document at desired path
$WordDocument = New-WordDocument $WordFilePath
#Add Title
Add-WordText -WordDocument $WordDocument -Alignment center -Text 'Orion Health Check' -FontSize 28

####### Process Health Check #######
$queries = Get-Content -Raw -Path queries.json | ConvertFrom-Json
foreach ($module in $modules.GetEnumerator()){
    #Check to see if the module is installed
    if ($module.Value -eq 1){
        #Get the name of the module
        $moduleName = $module.Name
        #Create Document Header
        #Get relevant queries
        $relQueries = $queries.$moduleName
        #Run Relevant Queries
        if ($relQueries){
            $moduleName
            Add-WordText -WordDocument $WordDocument -Text $moduleName -FontSize 20 -Bold $true -HeadingType Heading3
            foreach ($query in $relQueries){
                #Create table name
                $tableName = $query.table
                #Use the query to get info from Orion
                $result = Get-Results($query.query)
                #If result is not empty
                if ($result){
                    #Create the table with a title
                    Add-WordText -WordDocument $WordDocument -Text $tableName -FontSize 12 -Bold $true -HeadingType Heading5
                    Add-WordTable -WordDocument $WordDocument -DataTable $result -Design LightGrid -Supress $true
                }
                else{
                    $errmessage = "Could not create table '"+$tableName+"'. Check error log for more details."
                    Add-WordText -WordDocument $WordDocument -Text $errmessage -FontSize 12 -Color Red
                }
            }
        }
    }
}
#Save thw word document and open the file
Save-WordDocument $WordDocument
Invoke-Item $WordFilePath