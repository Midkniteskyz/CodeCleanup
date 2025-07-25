function Start-FTPWatcher {
    [CmdletBinding()]
    param (
        # FolderToMonitor to watch
        [Parameter()]
        [string]$FolderToMonitor = "C:\Users\aznkr\Desktop\Code\TestFolder\Outgoing",

        # Log folder
        [Parameter()]
        [string]$LogPath = "C:\FTP\Logs\Transfer"
    )
    
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $FolderToMonitor
        $watcher.Filter = "*.*"  # You can specify a specific file pattern here
        $watcher.IncludeSubdirectories = $false  # Set to true if you want to watch subdirectories
        
        $watcher.EnableRaisingEvents = $true

        # Check for the log path, create if non-existent
        Write-Host "Checking for $logpath"
        if (!(Test-path $logpath)) {
            Write-Host "$logpath Not Found. Creating."
            New-Item -Path $logpath -ItemType Directory
        }else{
            Write-Host "$logpath exists."
        }

        # Create a new logfile for this instance of the watcher
        $date = Get-Date
        $guid = [guid]::NewGuid() 
        $logname = $date.ToString("yyyyMMdd-HHmmss") + "-$guid"
        
        New-Item -Path "$logpath\" -Name "$logname.txt" -ItemType File 
    
        
        $onChangeScript = {

            $fileName = $eventArgs.Name
            
            $LogFileDetected = "[INFO]$filename Added to folder."

            $LogFileDetected | Out-File -Append -FilePath "$logpath\$logname"

        }

        Register-ObjectEvent -InputObject $watcher -EventName Created -Action $onChangeScript
    
    
    
        # Keep the script running to continue monitoring
        while ($true) {
            Start-Sleep -Seconds 5  # Sleep to prevent high CPU usage
        }

}

Start-FTPWatcher
