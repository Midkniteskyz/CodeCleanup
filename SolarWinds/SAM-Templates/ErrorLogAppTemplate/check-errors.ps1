param(
    [string]$rootFolder = "C:\Users\Ryan.Woolsey\OneDrive - Loop1\Documents\vscode\Muckleshoot\ErrorLogAppTemplate",
    [string]$searchString = "invalidpin"
)

# Check if rootFolder and searchString are provided
if (-not $rootFolder -or -not $searchString) {
    Write-Host "Usage: script.ps1 <rootFolder> <searchString>"
    exit 1
}

# Check if rootFolder exists
if (-not (Test-Path $rootFolder -PathType Container)) {
    Write-Host "Root folder '$rootFolder' does not exist."
    exit 1
}

# Get the latest date modified folder in the root directory
$latestFolder = Get-ChildItem -Path $rootFolder -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $latestFolder) {
    Write-Host "No folders found in the root folder."
    exit 1
}

# Get the latest date modified file in the latest date modified folder
$latestFile = Get-ChildItem -Path $latestFolder.FullName | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $latestFile) {
    Write-Host "No files found in the latest folder."
    exit 1
}

# Get the file name
$fileName = $latestFile.Name

# Get the latest line that contains the search string
$latestLine = Get-Content $latestFile.FullName | Select-String $searchString | Select-Object -Last 1

if ($latestLine) {
    Write-Host "Error found in file '$fileName' at line $($latestLine.LineNumber): $($latestLine.Line)"
    exit 1
} else {
    Write-Host "No errors found"
    exit 0
}
