# Top 10 Largest Folders Scanner
# This script scans a drive or directory and finds the largest folders by size

param(
    [Parameter(Mandatory=$false)]
    [string]$Path = "C:\",
    
    [Parameter(Mandatory=$false)]
    [int]$TopCount = 10,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = $null,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeSubfolders = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowProgress = $true
)

# Function to format file sizes
function Format-FileSize {
    param([long]$Size)
    
    if ($Size -ge 1TB) {
        return "{0:N2} TB" -f ($Size / 1TB)
    }
    elseif ($Size -ge 1GB) {
        return "{0:N2} GB" -f ($Size / 1GB)
    }
    elseif ($Size -ge 1MB) {
        return "{0:N2} MB" -f ($Size / 1MB)
    }
    elseif ($Size -ge 1KB) {
        return "{0:N2} KB" -f ($Size / 1KB)
    }
    else {
        return "{0} bytes" -f $Size
    }
}

# Function to get folder size (including all subfolders and files)
function Get-FolderSize {
    param(
        [string]$FolderPath,
        [switch]$ShowProgress
    )
    
    try {
        if ($ShowProgress) {
            Write-Progress -Activity "Calculating folder size" -Status "Scanning: $FolderPath" -PercentComplete -1
        }
        
        $size = 0
        $files = Get-ChildItem -Path $FolderPath -Recurse -File -Force -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {
            $size += $file.Length
        }
        
        return $size
    }
    catch {
        Write-Warning "Error calculating size for $FolderPath`: $($_.Exception.Message)"
        return 0
    }
}

# Validate input path
if (-not (Test-Path $Path)) {
    Write-Error "Path not found: $Path"
    exit 1
}

# Get the item to check if it's a file or directory
$item = Get-Item $Path
if ($item -is [System.IO.FileInfo]) {
    Write-Error "The specified path is a file, not a directory: $Path"
    exit 1
}

Write-Host "=== Top $TopCount Largest Folders Scanner ===" -ForegroundColor Cyan
Write-Host "Scanning Path: $Path" -ForegroundColor Yellow
Write-Host "Started at: $(Get-Date)" -ForegroundColor Yellow
Write-Host "Please wait while scanning folders..." -ForegroundColor Green
Write-Host ""

# Get all directories
try {
    if ($IncludeSubfolders) {
        Write-Host "Scanning all subdirectories recursively..." -ForegroundColor Yellow
        $directories = Get-ChildItem -Path $Path -Directory -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "Scanning first-level directories only..." -ForegroundColor Yellow
        $directories = Get-ChildItem -Path $Path -Directory -Force -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Error "Error accessing directories: $($_.Exception.Message)"
    exit 1
}

if ($directories.Count -eq 0) {
    Write-Host "No directories found in the specified path." -ForegroundColor Red
    exit 0
}

Write-Host "Found $($directories.Count) directories to analyze." -ForegroundColor Green
Write-Host ""

# Calculate folder sizes
$folderSizes = @()
$counter = 0

foreach ($dir in $directories) {
    $counter++
    
    if ($ShowProgress) {
        $percentComplete = [math]::Round(($counter / $directories.Count) * 100, 2)
        Write-Progress -Activity "Analyzing Folders" -Status "Processing: $($dir.Name) ($counter of $($directories.Count))" -PercentComplete $percentComplete
    }
    
    $size = Get-FolderSize -FolderPath $dir.FullName -ShowProgress:$ShowProgress
    
    $folderInfo = [PSCustomObject]@{
        Name = $dir.Name
        FullPath = $dir.FullName
        SizeBytes = $size
        SizeFormatted = Format-FileSize -Size $size
        LastModified = $dir.LastWriteTime
        Created = $dir.CreationTime
    }
    
    $folderSizes += $folderInfo
}

# Clear progress bar
if ($ShowProgress) {
    Write-Progress -Activity "Analyzing Folders" -Completed
}

# Sort by size and get top N
$topFolders = $folderSizes | Sort-Object SizeBytes -Descending | Select-Object -First $TopCount

# Display results
Write-Host ""
Write-Host "=== TOP $TopCount LARGEST FOLDERS ===" -ForegroundColor Cyan
Write-Host "Scan completed at: $(Get-Date)" -ForegroundColor Yellow
Write-Host ""

$rank = 1
foreach ($folder in $topFolders) {
    Write-Host "[$rank] " -NoNewline -ForegroundColor White
    Write-Host "$($folder.Name)" -ForegroundColor Green
    Write-Host "    Size: $($folder.SizeFormatted)" -ForegroundColor Yellow
    Write-Host "    Path: $($folder.FullPath)" -ForegroundColor Gray
    Write-Host "    Last Modified: $($folder.LastModified.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    Write-Host ""
    $rank++
}

# Summary statistics
$totalSize = ($folderSizes | Measure-Object -Property SizeBytes -Sum).Sum
$averageSize = ($folderSizes | Measure-Object -Property SizeBytes -Average).Average

Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total folders analyzed: $($folderSizes.Count)" -ForegroundColor White
Write-Host "Total size of all folders: $(Format-FileSize -Size $totalSize)" -ForegroundColor White
Write-Host "Average folder size: $(Format-FileSize -Size $averageSize)" -ForegroundColor White
Write-Host "Largest folder: $($topFolders[0].Name) ($(Format-FileSize -Size $topFolders[0].SizeBytes))" -ForegroundColor White

if ($topFolders.Count -gt 1) {
    Write-Host "Smallest in top $TopCount`: $($topFolders[-1].Name) ($(Format-FileSize -Size $topFolders[-1].SizeBytes))" -ForegroundColor White
}

# Export to CSV if requested
if ($OutputPath) {
    try {
        $topFolders | Select-Object Name, FullPath, SizeFormatted, SizeBytes, LastModified, Created | 
        Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host ""
        Write-Host "Results exported to: $OutputPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to export results: $($_.Exception.Message)"
    }
}

# Display usage examples
Write-Host ""
Write-Host "=== USAGE EXAMPLES ===" -ForegroundColor Cyan
Write-Host "Basic usage (scan C:\ drive):" -ForegroundColor Yellow
Write-Host "  .\script.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Scan specific directory:" -ForegroundColor Yellow
Write-Host "  .\script.ps1 -Path 'D:\MyFolder'" -ForegroundColor White
Write-Host ""
Write-Host "Get top 20 folders:" -ForegroundColor Yellow
Write-Host "  .\script.ps1 -Path 'C:\' -TopCount 20" -ForegroundColor White
Write-Host ""
Write-Host "Include all subdirectories:" -ForegroundColor Yellow
Write-Host "  .\script.ps1 -Path 'C:\' -IncludeSubfolders" -ForegroundColor White
Write-Host ""
Write-Host "Export results to CSV:" -ForegroundColor Yellow
Write-Host "  .\script.ps1 -Path 'C:\' -OutputPath 'C:\results.csv'" -ForegroundColor White
Write-Host ""
Write-Host "Run silently (no progress bars):" -ForegroundColor Yellow
Write-Host "  .\script.ps1 -Path 'C:\' -ShowProgress:`$false" -ForegroundColor White