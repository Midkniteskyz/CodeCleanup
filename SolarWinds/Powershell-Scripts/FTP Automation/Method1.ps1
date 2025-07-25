#To upload a single file, use the UploadFile method.

#Unique Variables
$FTPServer = "ftp://192.168.4.31"
$FTPUsername = "anonymous"
$FTPPassword = "Test2023!" 
$LocalDirectory = "/" 
$FileToUpload = "example.txt"

#Connect to the FTP Server
$ftp = [System.Net.FtpWebRequest]::create("$FTPServer/$FileToUpload")
$ftp.Credentials =  New-Object System.Net.NetworkCredential($FTPUsername,$FTPPassword)

#Upload file to FTP Server
$ftp.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile

#Verify the file was uploaded
$ftp.GetResponse()
 

#To delete a single file, use the DeleteFile method.

#Unique Variables
$FTPServer = "ftp://example.com/"
$FTPUsername = "username"
$FTPPassword = "password" 
$LocalDirectory = "C:\temp\" 
$FileToDelete = "example.txt"

#Connect to the FTP Server
$ftp = [System.Net.FtpWebRequest]::create("$FTPServer/$FileToDelete")
$ftp.Credentials =  New-Object System.Net.NetworkCredential($FTPUsername,$FTPPassword)

#Delete file on FTP Server
$ftp.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile

#Verify the file was uploaded
$ftp.GetResponse()
 

#To upload every file in a directory:

#Unique Variables
$FTPServer = "ftp://192.168.4.31"
$FTPUsername = "anonymous"
$FTPPassword = "Test2023!" 
$LocalDirectory = "C:\Users\Administrator\Desktop\Code\FTPTransfer\FileRepo" 

#Loop through every file
foreach($FileToUpload in (dir $LocalDirectory "*")){

    #Connect to the FTP Server
    $ftp = [System.Net.FtpWebRequest]::create("$FTPServer/$FileToUpload")
    $ftp.Credentials =  New-Object System.Net.NetworkCredential($FTPUsername,$FTPPassword)

    #Upload file to FTP Server
    $ftp.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile

    #Verify the file was uploaded
    $ftp.GetResponse()

    sleep 5
    
}

foreach($i in 1..10){
    New-Item -Name "TestFile$i.txt" -ItemType File -Value "There is text in here"
}