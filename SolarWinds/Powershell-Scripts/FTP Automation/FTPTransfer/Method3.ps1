# Replace these values with your actual FTP server details
$ftpServer = "192.168.4.31"
$ftpUsername = "anonymous"
$ftpPassword = "Test2023!"

# Path to the file you want to upload
$localFilePath = "/"

# Remote directory where you want to upload the file
$remoteDirectory = "/remote/directory/"

# Generate a temporary script file for FTP commands
$ftpScriptPath = [System.IO.Path]::GetTempFileName() + ".txt"
@"
open $ftpServer
$ftpUsername
$ftpPassword
cd $remoteDirectory
put "$localFilePath"
bye
"@ | Set-Content -Path $ftpScriptPath -Encoding ASCII

# Execute the FTP script using ftp.exe
Start-Process "ftp.exe" -ArgumentList "-s:$ftpScriptPath"

# Remove the temporary script file
Remove-Item $ftpScriptPath

# Log success or failure here
