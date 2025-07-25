function Create-ScheduledTask {
    [CmdletBinding()]
    param (
        [string]$TaskName,
        [string]$ScriptPath,
        [string]$LogName,
        [string]$TriggerIntervalMinutes = "1",
        [int]$ScriptTimeoutMinutes = 5
    )

    # Create the new task action
    $taskAction = New-ScheduledTaskAction `
                -Execute "powershell.exe" `
                -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""


    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    # $trigger = New-ScheduledTaskTrigger -RepetitionInterval ([TimeSpan]::FromMinutes($TriggerIntervalMinutes)) -RepetitionDuration ([TimeSpan]::MaxValue)

    # $taskTrigger.Delay = "PT5M"  # Wait 5 minutes before starting the task to allow any previous instance to complete

    # $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopIfIdleEnd

    # $task = Register-ScheduledTask -Action $taskAction -Trigger $taskTrigger -TaskName $TaskName -Settings $taskSettings -Force

    # Write-Host "Scheduled task '$TaskName' created."

    # $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
    # $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes($ScriptTimeoutMinutes)

    # $timeoutTaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command "
    # $eventMessage = 'Timeout reached for task: {0}' -f $TaskName
    # Write-EventLog -LogName $LogName -Source "TaskScheduler" -EventId 101 -Message $eventMessage -EntryType Warning`

    # $timeoutTaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes($ScriptTimeoutMinutes)

    # $timeoutTask = Register-ScheduledTask -Action $timeoutTaskAction -Trigger $timeoutTaskTrigger -TaskName "${TaskName}_Timeout" -Settings $taskSettings -Force

    # Write-Host "Timeout task '${TaskName}_Timeout' created."

}

Create-ScheduledTask -TaskName "MyScriptTask" -ScriptPath "C:\Path\To\Your\Script.ps1" -LogName "Application" -TriggerIntervalMinutes "1" -ScriptTimeoutMinutes 5


