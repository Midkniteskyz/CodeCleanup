# What to put in shortcut target: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File "C:\Users\RWoolsey\OneDrive - Loop1\VSCode\PowerShell\RestartZiti\Restart-Ziti.ps1"
# Set the execution policy for the current user
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force

$zitiprogramlocation = "C:\Program Files (x86)\NetFoundry Inc\Ziti Desktop Edge\ZitiDesktopEdge.exe"

# Kill Ziti Processes
Get-Process *ziti* -ErrorAction SilentlyContinue | ForEach-Object { 
    try {
        Stop-Process -Id $_.Id -Force
    }
    catch {
        Write-Host "Cannot stop process $($_.Name) ($($_.Id)): Access is denied"
    }
}

Start-Process $zitiprogramlocation
