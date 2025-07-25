$folderPath = "C:\Path\To\Your\Folder"
$processedFiles = @{}
$watcher = $null
$watcherAction = $null

function Remove-FileAndLogProcessed {
    param ($fileName)

    # Remove the file from the folder
    $filePath = Join-Path $folderPath $fileName
    Remove-Item -Path $filePath -Force

    # Log the processed file in the hashtable
    $processedFiles[$fileName] = Get-Date
    Write-Host "Processed and removed file: $fileName"
}

function Create-FileSystemWatcher {
    $global:watcher = New-Object System.IO.FileSystemWatcher
    $global:watcher.Path = $folderPath
    $global:watcher.Filter = "*.*"
    $global:watcher.IncludeSubdirectories = $false

    $global:watcher.EnableRaisingEvents = $true

    $global:watcherAction = {
        param ($sender, $eventArgs)
        $fileName = $eventArgs.Name

        lock ($processedFiles) {
            if (-not $processedFiles.ContainsKey($fileName)) {
                & Remove-FileAndLogProcessed -fileName $fileName
            } else {
                Write-Host "File already processed: $fileName"
            }
        }
    }

    Register-ObjectEvent -InputObject $global:watcher -EventName Created -Action $global:watcherAction
}

function Stop-FileSystemWatcher {
    if ($global:watcher -ne $null) {
        Unregister-Event -SourceIdentifier $global:watcher.EventIdentifier
        $global:watcher.Dispose()
        Write-Host "FileSystemWatcher stopped."
    }
    Exit
}

# Create FileSystemWatcher
Create-FileSystemWatcher

Write-Host "Press Ctrl+C to stop the FileSystemWatcher."

# Continuously loop to keep the script running
while ($true) {
    Start-Sleep -Seconds 5  # Sleep to prevent high CPU usage
}
