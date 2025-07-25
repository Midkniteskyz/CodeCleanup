# SolarWindsRemedyConnector.ps1

[CmdletBinding()]

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
    Specifies the Remedy login. Example is "Cleoado.Johnson"

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
    PS> C:\Program Files\PowerShell\7\pwsh.exe -File "C:\Remedy_API\REST_API_GetToken_CreateIncident-REST-METHOD.ps1" "https://" "cleoado" "ALERT: Node ${NodeName} is ${N=SwisEntity;M=Status}" "Host name: ${N=SwisEntity;M=DisplayName} IP address: ${N=SwisEntity;M=IP_Address} Location: ${N=SwisEntity;M=Location} Uplink type: ${N=Alerting;M=TriggeredMessage}" "2000" "3000" "AGGAA5V0GITM6AR2DIJGR1DUG8ZZKZ" "${N=Alerting;M=AlertObjectID}""${N=Alerting;M=Severity}"
    The following Command is using SolarWinds variables for some of the parameters. Example of Alert Trigger Action populated with SolarWinds variables "Node is Down":

    .EXAMPLE
    C:\Program Files\PowerShell\7\pwsh.exe -File "C:\Remedy_API\RemedyCreateSolarWindsAlertUpdate.ps1" "https://" "cleoado.johnson" "${N=SwisEntity;M=DisplayName}" "${N=SwisEntity;M=Status}" "${N=SwisEntity;M=IP_Address}" "${N=SwisEntity;M=Location}" "${N=Alerting;M=AlertMessage}" "${N=SwisEntity;M=DetailsUrl}" "${N=Alerting;M=AlertDetailsUrl}" "${N=Alerting;M=Severity}" "AGGAA5V0GITM6AR2DIJGR1DUG8ZZKZ" "${N=Alerting;M=AlertObjectID}"

#>


PARAM (
    [Parameter(Mandatory=$True)]
    [string]$RemedyHost,

    [Parameter(Mandatory=$True)]
    [string]$LoginID,

    [Parameter(Mandatory=$False)]
    [string]$NodeName,

    [Parameter(Mandatory=$False)]
    [string]$NodeStatus,

    [Parameter(Mandatory=$False)]
    [string]$IPAddress,

    [Parameter(Mandatory=$False)]
    [string]$NodeLocation,

    [Parameter(Mandatory=$False)]
    [string]$AlertMessage,

    [Parameter(Mandatory=$False)]
    [string]$NodeURL,

    [Parameter(Mandatory=$False)]
    [string]$AlertURL,

    [Parameter(Mandatory=$True)]
    [string]$Severity,

    [Parameter(Mandatory=$False)]
    [string]$TemplateID,

    [Parameter(Mandatory=$True)]
    [string]$AlertID
)

#----------------[ Declarations ]----------------

# Set Error Action
$ErrorActionPreference = "Stop"

# Set Execution Policy
Set-ExecutionPolicy -ExecutionPolicy Bypass

# Set log
$LogDestination = "C:\Remedy_API\Logs"
$filename = Get-Date -Format FileDateTime
Start-Transcript -Path "$LogDestination\$filename.txt" -NoClobber

# SolarWinds Login Creds
$SolarWindsUserName = ''
$SolarWindsUserPassword = ''
$SolarWindsHostName = 'localhost'

#----------------[ Functions ]------------------

function New-RemedyTicket
{
    [CmdletBinding()]

    Param
    (

    [Parameter(Mandatory=$True,Position = 0)]
    [string]$RemedyHost,

    [Parameter(Mandatory=$True,Position = 1)]
    [string]$LoginID,

    [Parameter(Mandatory=$True,Position = 2)]
    [string]$NodeName,
    
    [Parameter(Mandatory=$True,Position = 3)]
    [string]$NodeStatus,

    [Parameter(Mandatory=$True,Position = 4)]
    [string]$IPAddress,

    [Parameter(Mandatory=$True,Position = 5)]
    [string]$NodeLocation,

    [Parameter(Mandatory=$True,Position = 6)]
    [string]$AlertMessage,

    [Parameter(Mandatory=$True,Position = 7)]
    [string]$NodeURL,

    [Parameter(Mandatory=$True,Position = 8)]
    [string]$AlertURL,
    
    [Parameter(Mandatory=$True,Position = 9)]
    [string]$Severity,
    
    [Parameter(Mandatory=$True,Position = 10)]
    [string]$TemplateID    
        
    )

    Begin
    {
    
    # Pre-Defined variables: source is Incident Reported Source = "SolarWinds"; service is Incident Type = "User Service Restoration"
    $action = "CREATE"
    $jwtLoginURL = "/api/jwt/login" 
    $getTokenURL = $RemedyHost + $jwtLoginURL
    $rmdyApiUrl = "/api/arsys/v1/entry/HPD:IncidentInterface_Create?fields=values(Incident Number)"
    $createIncidentURL = $RemedyHost + $rmdyApiUrl
    $jwtLogoutURL = "/api/jwt/logout" 
    $releaseTokenURL = $RemedyHost + $jwtLogoutURL

    # Evaluate Impact and Urgency arguments based on Alert Severity 
    Switch ($Severity)
        {
            'Critical' {$Impact = $Urgency = 1000}
            'Serious' {$Impact = $Urgency = 2000}
            'Warning' {$Impact = $Urgency = 3000}
            'Informational' {$Impact = $Urgency = 4000}
            'Notice' {$Impact = $Urgency = 4000}
        }

    # Get token value from Jetty server in Remedy
    $response=Invoke-RestMethod -Uri $getTokenURL -Method 'POST' -ContentType 'application/x-www-form-urlencoded' -Body 'username=SolarWinds&password=Omn1$bus'

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

    }

    Process
    {

    # Create incident
    $response = Invoke-RestMethod -Uri $createIncidentURL -Method 'POST' -Headers $headers -Body $UpdatedBody

    }

    End
    {

    # Display the Response (Incident Number) for Acknowledgement
    $IncidentNumber = $response.values 

    # Release token
    $log_out=Invoke-RestMethod -Uri $releaseTokenURL -Method 'POST' -Headers $headers

    }

}

function Set-AlertNote
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory=$True,Position = 0)]
        [string]$SolarWindsUserName,

        [Parameter(Mandatory=$True,Position = 1)]
        [string]$SolarWindsUserPassword,

        [Parameter(Mandatory=$True,Position = 2)]
        [string]$SolarWindsHostName,

        [Parameter(Mandatory=$True,Position = 3)]
        $AlertID,

        [Parameter(Mandatory=$True,Position = 4)]
        $IncidentNumber
    )

    Begin
    {
        # Import the swispowershell module
        Import-Module swispowershell

        # Collect the arguments to use with invoke-swis
        $AlertObjectIds = @([int]$AlertID) 
        $String = [string]$IncidentNumber
        $FormattedString = "Incident Number: " + $String.Substring(18,15)

        # Declare the SWIS connection
        $SWIS = Connect-Swis -UserName $SolarWindsUserName -Password $SolarWindsUserPassword -Hostname $SolarWindsHostName

    <# VARIABLE CHECK
        Write-Host @"
        AlertObjectIDs: $AlertObjectIds
        Incident Number: $String
        Formatted Incident Number: $FormattedString
"@
#>
    }

    Process
    {
        # Pass the arguments to AppendNote
        Invoke-SwisVerb $swis -EntityName "Orion.AlertActive" -Verb "AppendNote" -Arguments @($AlertObjectIds, $FormattedString)
    }

    End
    {

    }

} # End Set-AlertNote Function

#----------------[ Main ]-----------------

Write-Host @"
$RemedyHost
$LoginID
$NodeName
$NodeStatus
$IPAddress
$NodeLocation
$AlertMessage
$NodeURL
$AlertURL
$Severity
$TemplateID
$AlertID
"@

Stop-Transcript
Exit
