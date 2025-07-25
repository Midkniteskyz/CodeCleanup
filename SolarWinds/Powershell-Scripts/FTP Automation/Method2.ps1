# Replace these values with your actual FTP server details
$ftpServer = "ftp://192.168.4.31"
$ftpUsername = "anonymous"
$ftpPassword = "Test2023!"

# Path to the file you want to upload
$localFilePath = "C:\Users\Administrator\Desktop\Code\FTPTransfer\example.txt"

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

# Log success or failure here
