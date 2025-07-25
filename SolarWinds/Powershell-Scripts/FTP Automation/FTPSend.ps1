
# Function to send a file to the FTP Server
function Start-FTPFileTransfer {
    [CmdletBinding()]
    param(
        # Show default settings
        [switch]$ShowSettings,
        
        # FTP Server
        [Parameter(Mandatory = $false)]
        [string]$FTPServer = "ftp://192.168.4.31",

        # File Extension to monitor. Default is .txt
        [Parameter(Mandatory = $false)]
        [string]$FTPUsername = "anonymous",

        # File Extension to monitor. Default is .txt
        [Parameter(Mandatory = $false)]
        [string]$FTPPassword = "Test2023!",

        # File Extension to monitor. Default is .txt
        [Parameter(Mandatory = $false)]
        [string]$FileToUpload = "C:\FTP\Test.txt"        
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

}


Set-ExecutionPolicy Unrestricted
$folder = 'C:\Users\Administrator\Desktop\stuff'
foreach($f in (gci $folder)){
    write-host "sending $f"
    Start-FTPFileTransfer -FileToUpload "C:\Users\Administrator\Desktop\stuff\testfile2.txt"
    sleep 2
    
}

