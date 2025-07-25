# Function to check various reboot indicators
function Test-PendingReboot {
    $rebootRequired = $false

    # Component Based Servicing
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
        Write-Host "Reboot pending: Component Based Servicing"
        $rebootRequired = $true
    }

    # Windows Update Auto Updates
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
        Write-Host "Reboot pending: Windows Update"
        $rebootRequired = $true
    }

    # Pending File Rename Operations
    $pendingFileRenameOps = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
    if ($pendingFileRenameOps) {
        Write-Host "Reboot pending: File Rename Operations"
        $rebootRequired = $true
    }

    # WMI (for SCCM or other enterprise systems)
    $wmi = Get-WmiObject -Namespace 'ROOT\ccm\ClientSDK' -Class 'CCM_ClientUtilities' -ErrorAction SilentlyContinue
    if ($wmi) {
        $status = $wmi.DetermineIfRebootPending()
        if ($status.RebootPending -eq $true) {
            Write-Host "Reboot pending: SCCM reports pending reboot"
            $rebootRequired = $true
        }
    }

    return $rebootRequired
}

# Run the function
if (Test-PendingReboot) {
    Write-Host "System reboot is required." -ForegroundColor Yellow
} else {
    Write-Host "No reboot is currently required." -ForegroundColor Green
}
