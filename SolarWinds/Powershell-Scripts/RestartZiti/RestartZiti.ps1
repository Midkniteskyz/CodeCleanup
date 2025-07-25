# Script to restart Ziti services and create a desktop shortcut
# Save this as RestartZiti.ps1

# Set the execution policy for the current user
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force

# Define Ziti program location
$zitiprogramlocation = "C:\Program Files (x86)\NetFoundry Inc\Ziti Desktop Edge\ZitiDesktopEdge.exe"

# Function to restart Ziti
function Restart-ZitiServices {
    Write-Host "Stopping Ziti processes..."
    # Kill Ziti Processes with improved error handling
    Get-Process *ziti* -ErrorAction SilentlyContinue | ForEach-Object { 
        try {
            Stop-Process -Id $_.Id -Force
            Write-Host "Stopped process $($_.Name) ($($_.Id))"
        }
        catch {
            Write-Host "Cannot stop process $($_.Name) ($($_.Id)): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # Small delay to ensure processes are fully terminated
    Start-Sleep -Seconds 2

    # Start Ziti
    Write-Host "Starting Ziti Desktop Edge..."
    Start-Process $zitiprogramlocation
    Write-Host "Ziti restart complete!" -ForegroundColor Green
}

# Create desktop shortcut if it doesn't exist
function Create-ZitiRestartShortcut {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path -Path $desktopPath -ChildPath "Restart Ziti.lnk"
    
    if (-not (Test-Path $shortcutPath)) {
        $scriptPath = $MyInvocation.MyCommand.Path
        
        # Create a shell object
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
        $Shortcut.IconLocation = $zitiprogramlocation
        $Shortcut.Description = "Restart Ziti Services"
        $Shortcut.Save()
        
        Write-Host "Shortcut created on desktop: 'Restart Ziti'" -ForegroundColor Green
    }
    else {
        Write-Host "Shortcut already exists on desktop" -ForegroundColor Yellow
    }
}

# If script is run directly (not through shortcut), create the shortcut
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Create-ZitiRestartShortcut
}

# Always restart the services when the script runs
Restart-ZitiServices

# Pause so user can see results if run manually
if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to continue..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}