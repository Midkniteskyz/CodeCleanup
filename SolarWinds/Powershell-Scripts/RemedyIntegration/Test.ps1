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
Function New-RemedyIncident {
    <#
    .SYNOPSIS
        Create a new Remedy Incident by taking in alert details from SolarWinds

    .NOTES
        Name: New-RemedyTicket
        Author: Stephen Ferrari, Ryan Wooolsey
        Version: 1.0
        DateCreated: 2022-09-01

    .PARAMETER RemedyHost
        Required. CS = "https://csssprdwvars52.cvp.cs:443". AJ = "https://ajssprdwvars52.cvp.cs:443". CSNon = . AJNon = .

    .PARAMETER LoginID
        Required. TBD

    .PARAMETER Description
        Required. Populates "Summary" in Remedy Incident. SWQL: ${N=Alerting;M=AlertDescription}

    .PARAMETER DetailedDescription
        Required. Populates the "Notes" in Remedy Incident. SWQL: ${N=Alerting;M=AlertMessage}

    .PARAMETER Severity
        Required. Impact & Urgency (required by Remedy), are calcuated given the "Severity". SWQL: ${N=Alerting;M=Severity}

    .PARAMETER Organization
        Required. Related to the "Customer" CP in SolarWinds. SWQL: ${N=SwisEntity;M=CustomProperties.Customer}

    .PARAMETER SupportGroup
        Required. Related to the "Team" CP in SolarWinds. SWQL: ${N=SwisEntity;M=CustomProperties.Team}

    .EXAMPLE
        New-RemedyIncident -RemedyHost "<>" -LoginID -Description -DetailedDescription -Severity -Organization -SupportGroup

    #>

        [CmdletBinding()]
        PARAM(
            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
                )]
            [string[]]  $RemedyHost,

            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
                )]
            [string[]]  $LoginID,

            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
                )]
            [string[]]  $Description,

            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
                )]
            [string[]]  $DetailedDescription,

            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
                )]
            [string[]]  $Severity,

            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
                )]
            [string[]]  $Origanization,

            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
                )]
            [string[]]  $SupportGroup
        )

        BEGIN {

            # Evaluate Impact and Urgency arguments based on Alert Severity
            Switch ($Severity) {
                'Critical' {$Impact = $Urgency = 1000}
                'Serious' {$Impact = $Urgency = 2000}
                'Warning' {$Impact = $Urgency = 3000}
                'Informational' {$Impact = $Urgency = 4000}
                'Warning' {$Impact = $Urgency = 4000}
            }

            $TemplateCollection = @{
                # This list of hashtables should mirror "Organization" in Remedy. Corresponds to "Customer" in SolarWinds
                EA = @{
                    # <SuportGroup> = <TemplateGUID> | Key sould mirror the "Support Group" in Remedy. Value is the GUID of the Remedy template. Corresponds to "Team" in SolarWinds
                    "Application Support" = "Temp1"
                    "Windows" = "Temp2"
                }
                SG = @{
                    "Account Management" = "Temp3"
                    "Config Mgmt" = "Temp4"
                    "Data Management" = "Temp5"
                    "DBA - Oracle" = "Temp6"
                    "DBA - SQL" = "Temp7"
                    "Development" = "Temp8"
                    "Linux" = "Temp9"
                    "MQ Administration" = "Temp10"
                    "O&M" = "Temp11"
                    "OSC Approval" = "Temp12"
                    "SDT" = "Temp13"
                    "Security Approval" = "Temp14"
                    "SG Application Development" = "Temp15"
                    "SG CM Approval" = "Temp16"
                    "Windows" = "Temp17"
                }
                STAMP = @{
                    "Backup/Recovery" = "Temp18"
                    "Gitlab" = "Temp19"
                    "Linux" = "Temp20"
                    "Monitoring" = "AGGAA5V0GITM6AR6SI4LR5SN6PHSR9"
                    "MS SQL DBA" = "Temp22"
                    "Network" = "Temp23"
                    "Oracle DBA" = "Temp24"
                    "Platform" = "Temp25"
                    "Remedy" = "AGGAA5V0GITM6AR2DIJGR1DUG8ZZKZ"
                    "Security" = "Temp27"
                    "Storage/SAN" = "Temp28"
                    "UNIX" = "Temp29"
                    "Virtualization" = "Temp30"
                    "Windows" = "Temp31"
                }
                TIM = @{
                    "Accenture" = "Temp32"
                    "Account Management" = "Temp33"
                    "Adjudication"= "Temp34"
                    "Application Support" = "Temp35"
                    "Data Management" = "Temp36"
                    "DBA - Oracle" = "Temp37"
                    "DBA - SQL" = "Temp38"
                    "Deployment Team" = "Temp39"
                    "Development" = "Temp40"
                    "Infrastructure" = "Temp41"
                    "Linux" = "Temp42"
                    "O&M" = "Temp43"
                    "System Engineering" = "Temp44"
                    "Windows" = "Temp45"
                }
                TVS = @{
                    "Account Management" = "Temp46"
                    "Application Support" = "Temp47"
                    "Data Management" = "Temp48"
                    "DBA - SQL" = "Temp49"
                    "Development" = "Temp50"
                    "Linux" = "Temp51"
                    "MQ Administration" = "Temp52"
                    "O&M" = "Temp53"
                    "Windows" = "Temp54"
                }
            }

            $RemedyTemplate = $TemplateCollection.$Organization.$SupportGroup

            # Pre-Defined variables: source is Incident Reported Source = "SolarWinds"; service is Incident Type = "User Service Restoration"
            $Action = "CREATE"
            $GetTokenURL = $RemedyHost + "/api/jwt/login"
            $CreateIncidentURL = $RemedyHost + "/api/arsys/v1/entry/HPD:IncidentInterface_Create?fields=values(Incident Number)"
            $ReleaseTokenURL = $RemedyHost + "/api/jwt/logout"

            # Get token value from Jetty server in Remedy
            $Response = Invoke-RestMethod -Uri $GetTokenURL -Method 'POST' -ContentType 'application/x-www-form-urlencoded' -Body 'username=SolarWinds&password=Omn1$bus'

            # Create token
            $Token ="AR-JWT "+ $Response

            $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $Headers.Add("Content-Type", "application/json")
            $Headers.Add("Authorization", $Token)

            $Body = @{
                values = @{
                    z1D_Action = $Action
                    Login_ID = $LoginID
                    Description = $Description # Detailed_Decription <-- Note Spelling. Missing 's'
                    Detailed_Decription = $Detailed_Description
                    Impact = $Impact
                    Urgency = $Urgency
                    TemplateID = $RemedyTemplate
                }
            }

            $UpdateBody = ConvertTo-Json $Body
        }

        PROCESS {
            $CreateIncident = Invoke-RestMethod -Uri $CreateIncidentURL -Method 'POST' -Headers $Headers -Body $UpdateBody
        }

        END {
            # Release Token
            Invoke-RestMethod -Uri $ReleaseTokenURL -Method 'POST' -Headers $Headers

            # Display the Response (Incident Number) for Acknowledgment
            $IncidentNumber = $CreateIncident.Values
            return $IncidentNumber
        }
    }

Function Update-SolarWinds {
    <#
    .SYNOPSIS
        Update SolarWinds Alert with note or acknowledgement

    .NOTES
        Name: Update-SolarWinds
        Author: Ryan Woolsey
        Version: 1.0
        DateCreated: 2022-09-01

    .EXAMPLE
        Update-SolarWinds -AlertNote "<Note>" -Acknowledged "True"

    #>
        [CmdletBinding()]
        PARAM(
            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
                )]
            [string[]]  $AlertID,

            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
                )]
            [string[]]  $IncidentNumber,

            [Parameter(
                Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
                )]
            [string[]]  $Acknowledged,

            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
                )]
            [string[]]  $SolarWindsUserName,

            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
                )]
            [string[]]  $SolarWindsUserPassword
        )

        BEGIN {
            # Import the swispowershell module
            Import-Module swispowershell

            # Collect the arguments to use with invoke-swis
            $AlertObjectIds = @([int]$AlertID)
            $String = [string]$IncidentNumber
            $FormattedString = "Incident Number: " + $String.Substring(18,15)

        }

        PROCESS {
            # Set the SWIS connection
            $SWIS = Connect-Swis -UserName $SolarWindsUserName -Password $SolarWindsUserPassword -Hostname $SolarWindsHostName

            # Take the AlertObjectID and AppendNote
            Invoke-SwisVerb $swis -EntityName "Orion.AlertActive" -Verb "AppendNote" -Arguments @($AlertObjectIds, $FormattedString)
        }

        END {}
    }

#----------------[ Main ]-----------------

Stop-Transcript
Exit