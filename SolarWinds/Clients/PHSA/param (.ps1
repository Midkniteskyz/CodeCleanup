param (
    [string]$Path = "C:\",        # Default path
    [int]$Top = 10                # How many top folders to show
)

# Validate path
if (-not (Test-Path -Path $Path)) {
    Write-Error "The specified path '$Path' does not exist."
    return
}

# Get folder sizes
$folderSizes = Get-ChildItem -Path $Path -Directory -Force | ForEach-Object {
    $folderPath = $_.FullName
    try {
        $size = (Get-ChildItem -Path $folderPath -Recurse -Force -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            Folder = $folderPath
            SizeGB = [math]::Round($size / 1GB, 2)
        }
    } catch {
        Write-Warning "Failed to calculate size for $folderPath"
    }
}

# Sort and display
$folderSizes |
    Sort-Object -Property SizeGB -Descending |
    Select-Object -First $Top 