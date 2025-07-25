function Get-SystemDCOMErrors {
    <#
    .SYNOPSIS
    Checks system event logs for DCOM errors, TCP connection states, and SolarWinds logs over the last 24 hours and 7 days.

    .DESCRIPTION
    This function retrieves various event logs and statistics, including DCOM errors, TCP connection states, and SolarWinds event logs.
    It outputs the results to the console and handles any errors encountered during the process.

    .EXAMPLE
    Get-SystemEventLogs
    #>

    # Get DCOM Errors from the last 24 hours
    Write-Host "DCOM-------------------------------"
    Write-Host "-----------------------------------"
    $DCOM = Get-WinEvent -LogName System | 
            Where-Object { ($_.ProviderName -like "Microsoft-Windows-DistributedCOM") -and 
                           ($_.Id -eq 10028) -and 
                           ($_.TimeCreated -gt (Get-Date).AddHours(-24)) }

    $DCOMIPs = @()
    foreach ($D in $DCOM) {
        $DCOMfr = $D.Message.IndexOf("computer", 1)
        $DCOMto = $D.Message.IndexOf("using")
        if ($DCOMfr -gt -1 -and $DCOMto -gt -1) {
            $DCOMip = $D.Message.Substring($DCOMfr + 9, $DCOMto - $DCOMfr - 9)
            $DCOMIPs += $DCOMip -replace '\.$'
        }
    }

    if ($DCOM.Count -gt 0) {
        Write-Host "Total DCOM Errors in the last 24 hours: $($DCOM.Count)"
        $DCOMIPs | Group-Object | Sort-Object Count -Descending | Format-Table -Property Name, Count
    } else {
        Write-Host "No DCOM Errors"
    }

    Write-Host " "
    
    # Check TCP connection states
    Write-Host "CloseWait, TimeWait----------------"
    Write-Host "-----------------------------------"
    $closewait = (Get-NetTCPConnection -State CloseWait -ErrorAction SilentlyContinue).Count
    $timewait = (Get-NetTCPConnection -State TimeWait -ErrorAction SilentlyContinue).Count 

    if (($closewait -gt 300) -or ($timewait -gt 300)) {
        Write-Host "Bad: CloseWait: $closewait   TimeWait: $timewait"
    } else {
        Write-Host "Good: CloseWait: $closewait   TimeWait: $timewait"
    }
    Write-Host "Both values should be less than 300"

    Write-Host " "
    
    # Function to get event counts
    function Get-EventCount {
        param (
            [string]$LogName,
            [int]$Level,
            [int]$DaysAgo
        )
        try {
            return Get-WinEvent -ErrorAction Stop -FilterHashtable @{LogName = $LogName; Level = $Level; StartTime = (Get-Date).AddDays(-$DaysAgo)}
        } catch {
            return @()
        }
    }

    # Get SolarWinds events
    Write-Host "Event Log, SolarWinds (last 24 hours)-----------------------------------"
    $EventsSolarWindsNETWarning = Get-EventCount -LogName 'SolarWinds.NET' -Level 3 -DaysAgo 1
    Write-Host "Message.EventsSolarWindsNETWarning:  SolarWindsNETWarning"
    Write-Host "Statistic.EventsSolarWindsNETWarning: $($EventsSolarWindsNETWarning.Count)"

    $EventsSolarWindsNETError = Get-EventCount -LogName 'SolarWinds.NET' -Level 2 -DaysAgo 1
    Write-Host "Message.EventsSolarWindsNETError:  SolarWindsNETError"
    Write-Host "Statistic.EventsSolarWindsNETError: $($EventsSolarWindsNETError.Count)"

    # Get SWI Logs events
    Write-Host "SWI Logs (last 24 hours)-----------------------------------"
    $EventsSWILogsWarning = Get-EventCount -LogName 'SWI Logs' -Level 3 -DaysAgo 1
    Write-Host "Message.EventsSWILogsWarning:  SWILogsWarning"
    Write-Host "Statistic.EventsSWILogsWarning: $($EventsSWILogsWarning.Count)"

    $EventsSWILogsError = Get-EventCount -LogName 'SWI Logs' -Level 2 -DaysAgo 1
    Write-Host "Message.EventsSWILogsError:  SWILogsError"
    Write-Host "Statistic.EventsSWILogsError: $($EventsSWILogsError.Count)"

    # Get System events
    Write-Host "System Events (last 24 hours)-----------------------------------"
    $EventsSystemWarning = Get-EventCount -LogName 'System' -Level 3 -DaysAgo 1
    Write-Host "Message.EventsSystemWarning:  EventsSystemWarning"
    Write-Host "Statistic.EventsSystemWarning: $($EventsSystemWarning.Count)"

    $EventsSystemError = Get-EventCount -LogName 'System' -Level 2 -DaysAgo 1
    Write-Host "Message.EventsSystemError:  EventsSystemError"
    Write-Host "Statistic.EventsSystemError: $($EventsSystemError.Count)"

    # Get Application events
    Write-Host "Application Events (last 24 hours)-----------------------------------"
    $EventsApplicationWarning = Get-EventCount -LogName 'Application' -Level 3 -DaysAgo 1
    Write-Host "Message.EventsApplicationWarning:  EventsApplicationWarning"
    Write-Host "Statistic.EventsApplicationWarning: $($EventsApplicationWarning.Count)"

    $EventsApplicationError = Get-EventCount -LogName 'Application' -Level 2 -DaysAgo 1
    Write-Host "Message.EventsApplicationError:  EventsApplicationError"
    Write-Host "Statistic.EventsApplicationError: $($EventsApplicationError.Count)"

    Write-Host " "
    
    # Repeat for last 7 days
    Write-Host "Event Log, SolarWinds (last 7 days)-----------------------------------"
    $EventsSolarWindsNETWarning = Get-EventCount -LogName 'SolarWinds.NET' -Level 3 -DaysAgo 7
    Write-Host "Message.EventsSolarWindsNETWarning:  SolarWindsNETWarning"
    Write-Host "Statistic.EventsSolarWindsNETWarning: $($EventsSolarWindsNETWarning.Count)"

    $EventsSolarWindsNETError = Get-EventCount -LogName 'SolarWinds.NET' -Level 2 -DaysAgo 7
    Write-Host "Message.EventsSolarWindsNETError:  SolarWindsNETError"
    Write-Host "Statistic.EventsSolarWindsNETError: $($EventsSolarWindsNETError.Count)"

    # Get SWI Logs events for 7 days
    Write-Host "SWI Logs (last 7 days)-----------------------------------"
    $EventsSWILogsWarning = Get-EventCount -LogName 'SWI Logs' -Level 3 -DaysAgo 7
    Write-Host "Message.EventsSWILogsWarning:  SWILogsWarning"
    Write-Host "Statistic.EventsSWILogsWarning: $($EventsSWILogsWarning.Count)"

    $EventsSWILogsError = Get-EventCount -LogName 'SWI Logs' -Level 2 -DaysAgo 7
    Write-Host "Message.EventsSWILogsError:  SWILogsError"
    Write-Host "Statistic.EventsSWILogsError: $($EventsSWILogsError.Count)"

    # Get System events for 7 days
    Write-Host "System Events (last 7 days)-----------------------------------"
    $EventsSystemWarning = Get-EventCount -LogName 'System' -Level 3 -DaysAgo 7
    Write-Host "Message.EventsSystemWarning:  EventsSystemWarning"
    Write-Host "Statistic.EventsSystemWarning: $($EventsSystemWarning.Count)"

    $EventsSystemError = Get-EventCount -LogName 'System' -Level 2 -DaysAgo 7
    Write-Host "Message.EventsSystemError:  EventsSystemError"
    Write-Host "Statistic.EventsSystemError: $($EventsSystemError.Count)"

    # Get Application events for 7 days
    Write-Host "Application Events (last 7 days)-----------------------------------"
    $EventsApplicationWarning = Get-EventCount -LogName 'Application' -Level 3 -DaysAgo 7
    Write-Host "Message.EventsApplicationWarning:  EventsApplicationWarning"
    Write-Host "Statistic.EventsApplicationWarning: $($EventsApplicationWarning.Count)"

    $EventsApplicationError = Get-EventCount -LogName 'Application' -Level 2 -DaysAgo 7
    Write-Host "Message.EventsApplicationError:  EventsApplicationError"
    Write-Host "Statistic.EventsApplicationError: $($EventsApplicationError.Count)"
}

# Call the function to execute
Get-SystemDCOMErrors
