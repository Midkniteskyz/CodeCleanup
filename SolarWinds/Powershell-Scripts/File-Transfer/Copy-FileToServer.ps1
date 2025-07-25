# Example Command: .\Copy-FileToServers.ps1 -SourceFile "C:\path\to\source\file.txt" -DestinationPath "C:\destination\path" -ServerListFile "C:\path\to\serverlist.txt"

# Define parameters for the script
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceFile,
    
    [Parameter(Mandatory=$true)]
    [string]$DestinationPath,
    
    [Parameter(Mandatory=$true)]
    [string]$ServerListFile,
    
    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]$Credential
)

# Function to test server connectivity
function Test-ServerConnection {
    param($ServerName)
    Test-Connection -ComputerName $ServerName -Count 1 -Quiet
}

# Import the list of servers from a text file
$Servers = Get-Content $ServerListFile

# Initialize arrays for success and failure tracking
$SuccessfulCopies = @()
$FailedCopies = @()

# Verify source file exists
if (-not (Test-Path $SourceFile)) {
    Write-Error "Source file not found: $SourceFile"
    exit 1
}

foreach ($Server in $Servers) {
    Write-Host "Processing server: $Server" -ForegroundColor Cyan
    
    # Test if server is reachable
    if (-not (Test-ServerConnection $Server)) {
        Write-Warning "Unable to connect to server: $Server"
        $FailedCopies += $Server
        continue
    }
    
    try {
        # Create destination folder if it doesn't exist
        $RemotePath = "\\$Server\$($DestinationPath.Replace(':', '$'))"
        if (-not (Test-Path $RemotePath)) {
            New-Item -Path $RemotePath -ItemType Directory -Force -ErrorAction Stop
        }
        
        # Copy the file
        Copy-Item -Path $SourceFile -Destination $RemotePath -Force -ErrorAction Stop
        
        Write-Host "Successfully copied file to $Server" -ForegroundColor Green
        $SuccessfulCopies += $Server
    }
    catch {
        Write-Error "Failed to copy file to $Server. Error: $_"
        $FailedCopies += $Server
    }
}

# Generate summary report
Write-Host "`nCopy Operation Summary:" -ForegroundColor Yellow
Write-Host "Successful copies: $($SuccessfulCopies.Count)" -ForegroundColor Green
Write-Host "Failed copies: $($FailedCopies.Count)" -ForegroundColor Red

if ($FailedCopies.Count -gt 0) {
    Write-Host "`nFailed Servers:" -ForegroundColor Red
    $FailedCopies | ForEach-Object { Write-Host $_ }
}