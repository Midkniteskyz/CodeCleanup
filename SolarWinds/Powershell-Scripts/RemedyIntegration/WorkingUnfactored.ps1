<#
    .NAME
    REST_API_GetToken_CreateIncident-REST-METHOD.ps1

    .SYNOPSIS
    Use JSON to create a Remedy Incident. Values are obtained from the triggered Alert from SolarWinds.

    .Description
    When an alert is triggered in SolarWinds, a trigger action of "Execute a Remote Program" is ran.

    - Authentication: https://docs.bmc.com/docs/ars91/en/login-information-609071516.html#Logininformation-token

    .AUTHOR
    Stephen Ferrari

    .VERSION
    19

    .PARAMETER RemedyHost
    Specifies the Remedy Host. Example is "http://<RemedyAppServer>:8443"

    .PARAMETER LoginID
    Specifies the Remedy login. Example is "Cleoado"

    .PARAMETER Description
    Specifies the Incident Summary. Includes the SWIS queries ${NodeName}, ${Status}

    .PARAMETER Detailed_Description
    Specifies the Incident Details (Notes Field)

    .PARAMETER Impact
    Specifies the Impact ID.

    .PARAMETER Urgency
    Specifies the Urgency ID.

    .PARAMETER TemplateID
    Specifies the Incident Template (GUID). The template will be pointer to the group that remedy will assign the ticket too. 

    .OUTPUTS
    System.String. Incident number from Remedy.

    .EXAMPLE
    PS> C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy unrestricted -File <ScriptLocation> <RemedyHost> <LoginID> <Description> <Detailed_Description> <Impact> <Urgency> <TemplateID>
    Default usage in a terminal.

    .EXAMPLE
    PS> C:\Program Files\PowerShell\7\pwsh.exe -File "C:\Remedy_API\REST_API_GetToken_CreateIncident-REST-METHOD.ps1" "https://" "cleoado.johnson" "ALERT: Node ${NodeName} is ${N=SwisEntity;M=Status}" "Host name: ${N=SwisEntity;M=DisplayName} IP address: ${N=SwisEntity;M=IP_Address} Location: ${N=SwisEntity;M=Location} Uplink type: ${N=Alerting;M=TriggeredMessage}" "2000" "3000" "AGGAA5V0GITM6AR2DIJGR1DUG8ZZKZ" "${N=Alerting;M=AlertObjectID}""${N=Alerting;M=Severity}"
    The following Command is using SolarWinds variables for some of the parameters. Example of Alert Trigger Action populated with SolarWinds variables "Node is Down":
#>

# Param([string]$RemedyHost,[string]$LoginID,[string]$Description,[string]$Detailed_Description,[string]$TemplateID,[string]$AlertID,[string]$Severity)

Param(
    [string]$RemedyHost,
    [string]$LoginID,
    [string]$Description,
    [string]$Detailed_Description,
    [string]$TemplateID,
    [string]$Severity,
    [string]$AlertID
    )

Set-ExecutionPolicy -ExecutionPolicy Bypass

$filename = Get-Date -Format FileDateTime
Start-Transcript -Path "C:\Remedy_API\Logs\$filename.txt" -NoClobber

# Pre-Defined variables: source is Incident Reported Source = "SolarWinds"; service is Incident Type = "User Service Restoration"
    $action = "CREATE"

    $jwtLoginURL = "/api/jwt/login"
    $getTokenURL = $RemedyHost + $jwtLoginURL

    $rmdyApiUrl = "/api/arsys/v1/entry/HPD:IncidentInterface_Create?fields=values(Incident Number)"
    $createIncidentURL = $RemedyHost + $rmdyApiUrl

    $jwtLogoutURL = "/api/jwt/logout"
    $releaseTokenURL = $RemedyHost + $jwtLogoutURL

Switch ($Severity)
{
    'Critical' {$Impact = $Urgency = 1000}
    'Serious' {$Impact = $Urgency = 2000}
    'Warning' {$Impact = $Urgency = 3000}
    'Informational' {$Impact = $Urgency = 4000}
    'Notice' {$Impact = $Urgency = 4000}
}

# DEBUG
Write-Host "*********** DEBUG Line 72-75 ***********"
Write-Host "Remedy Host: $RemedyHost `nLogin_ID: $LoginID `nDescription: $Description `nImpact: $Impact `nUrgency: $Urgency `nTemplateID: $TemplateID"
Write-Host "Get Token URL: $getTokenURL `nCreate Incident URL: $createIncidentURL `nRelease Token URL: $releaseTokenURL"
Write-Host "*****************************"

# Get token value from Jetty server in Remedy
    $response=Invoke-RestMethod -Uri $getTokenURL -Method 'POST' -ContentType 'application/x-www-form-urlencoded' -Body 'username=SolarWinds&password=Omn1$bus'

Write-Host "*********** DEBUG Line 81 ***********"
Write-Host "Response : $response"
Write-Host "*****************************"

# Create token
    $token="AR-JWT "+$response

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", $token)

    $body = @{
            values = @{
                z1D_Action = $action
                Login_ID = $LoginID
                Description = $Description
                Detailed_Decription = $Detailed_Description
                Impact = $Impact
                Urgency = $Urgency
                TemplateID = $TemplateID
            }
        }

#Detailed_Decription <-- Note the spelling.  Missing 's'
    $UpdatedBody = ConvertTo-Json $body

# Create incident
    $response = Invoke-RestMethod -Uri $createIncidentURL -Method 'POST' -Headers $headers -Body $UpdatedBody

# Display the Response (Incident Number) for Acknowledgement
    $IncidentNumber = $response.values

# Release token
    $log_out=Invoke-RestMethod -Uri $releaseTokenURL -Method 'POST' -Headers $headers

Write-Host "*********** DEBUG 85-113 ***********"
Write-host "$token"
Write-Host "$UpdatedBody"
Write-Host "$log_out"
Write-Host "Object ID: $AlertID"
Write-Host "Response : $response"
Write-Host "Incident Number: $IncidentNumber"
Write-Host "Severity: $Severity"
Write-Host "*****************************"


#####################################################################################
########## SWIS Function ##########
#####################################################################################


sleep 10

Import-Module swispowershell


# Connect to SWIS
    $UserName = ''
    $UserPassword = ''
    $swis = Connect-Swis -UserName $UserName -Password $UserPassword -Hostname localhost


# The Object ID of the alert
    $AlertObjectIds = @([int]$AlertID)
    $String = [string]$IncidentNumber
    $FormattedString = "Incident Number: " + $String.Substring(18,15)


Write-Host "*********** DEBUG 142-144 ***********"
Write-Host $alertObjectIds
Write-Host $string
Write-Host $formattedstring
Write-Host "*****************************"

# Take the AlertObjectID and AppendNot
    Invoke-SwisVerb $swis -EntityName "Orion.AlertActive" -Verb "AppendNote" -Arguments @($AlertObjectIds, $FormattedString)

Stop-Transcript

exit



# If return success then Set Acknowledge to true

# Else stay unacknowledged

# $query = @" SELECT DateTime, Level, logEntry.LogMessageSource.IPAddress, logEntry.LogMessageSource.Caption AS NodeName, logEntry.LogType.Type AS SourceType, Message FROM Orion.OLM.LogEntry as logEntry WHERE DateTime >= @startDate AND DateTime <= @endDate "@

# Get-SwisData -SwisConnection $swis -Query $query ` -Parameters @{startDate = $startDate;endDate = $endDate}

<#
***** Useful Queries *****

-The ID of the alert
$alertid = '${N=Alerting;M=AlertID}'

- The AlertActiveID of the alert
$alertactiveid = '${N=Alerting;M=AlertActiveID}'

#>
