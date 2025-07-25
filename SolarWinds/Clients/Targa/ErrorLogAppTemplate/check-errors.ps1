function Check-ContainerLog {
    # Check-ContainerLog -rootFolder "C:\Users\RWoolsey\OneDrive - Loop1\VSCode\Clients\Targa\TestFolder" -searchString "*CDT*"
    param(
        [string]$rootFolder,  # Path to the folder containing the log files
        [string]$searchString # String to search for in the log file
    )

    # Validate that the rootFolder exists
    if (-not (Test-Path $rootFolder -PathType Container)) {
        Write-Host "Error: The specified folder '$rootFolder' does not exist."
        return
    }

    try {
        # Get all files in the folder, sort by LastWriteTime, and select the latest one
        $LastFile = Get-ChildItem $rootFolder | Where-Object { $_.Name -like "*.container.*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1

        # Check if a file was found
        if (-not $LastFile) {
            Write-Host "Error: No files matching the pattern '*.container.*' found in '$rootFolder'."
            return
        }

        # Read the content of the file and search for the specified string
        $ReadFile = Get-Content $LastFile.FullName | Select-String $searchString
        $LatestMatch = $ReadFile | Select-Object -Last 1
        $TotalMatches = $ReadFile.Count

        # Check if any matches were found
        if ($TotalMatches -gt 0) {
            Write-Host "Error: '$searchString' found in file '$($LastFile.FullName)'."
            Write-Host "Latest match at line $($LatestMatch.LineNumber): $($LatestMatch.Line)"
            Write-Host "Total occurrences: $TotalMatches"
            # Optionally, set an exit code for critical status
            # exit 3
        } else {
            Write-Host "No errors found in '$($LastFile.FullName)'."
            # Optionally, set an exit code for success
            # exit 0
        }

    } catch {
        # Catch and display any errors that occur during execution
        Write-Host "Error: An exception occurred - $($_.Exception.Message)"
    }
}


function Check-HttpServerLog {
    # Check-HttpServerLog -rootFolder "C:\Users\RWoolsey\OneDrive - Loop1\VSCode\Clients\Targa\TestFolder" -fileName "*.shared_http_server.*" -LastWriteMinutes 30

    param(
        [string]$rootFolder,
        [string]$fileName,
        [int]$LastWriteMinutes = 60  # Default to 60 minutes if not provided
    )

    # Check if rootFolder and fileName are provided
    if (-not $rootFolder -or -not $fileName) {
        Write-Host "Error: Missing root folder or file name."
        return
    }

    # Check if rootFolder exists
    if (-not (Test-Path $rootFolder -PathType Container)) {
        Write-Host "Error: Root folder '$rootFolder' does not exist."
        return
    }

    try {
        # Get the current date and time
        $currentTime = Get-Date

        # Get all files in the folder matching the file name pattern
        $LastFile = Get-ChildItem $rootFolder | Where-Object { $_.Name -like $fileName } | Sort-Object LastWriteTime -Descending | Select-Object -First 1

        # Check if a file was found
        if (-not $LastFile) {
            Write-Host "Error: No files found matching '$fileName' in '$rootFolder'."
            # return
            # exit 3
        }

        # Calculate the time difference between now and the file's last write time
        $timeDifference = ($currentTime - $LastFile.LastWriteTime).TotalMinutes

        # Check if the file was written within the last specified minutes
        if ($timeDifference -le $LastWriteMinutes) {
            Write-Host "File '$($LastFile.Name)' was written within the last $LastWriteMinutes minutes."
            # return $true
            # exit 0
        } else {
            Write-Host "File '$($LastFile.Name)' was not written within the last $LastWriteMinutes minutes."
            # return $false
            # exit 3
        }
    } catch {
        # Handle any errors that occur during execution
        Write-Host "Error: An error occurred - $($_.Exception.Message)"
    }
}


# Check-ContainerLog -rootFolder "C:\Users\RWoolsey\OneDrive - Loop1\VSCode\Clients\Targa\TestFolder" -searchString "CDT"

# Check-HttpServerLog -rootFolder "C:\Users\RWoolsey\OneDrive - Loop1\VSCode\Clients\Targa\TestFolder" -fileName "*.shared_http_server.*" -LastWriteMinutes 120