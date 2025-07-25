<#
.SYNOPSIS
Generates an XML configuration file based on specified templates for SolarWinds installation.

.DESCRIPTION
This script generates an XML configuration file for SolarWinds installation. It allows you to select from pre-defined templates 
such as 'FreshInstall', 'InstallHAwithWindowsAuth', 'InstallAWE', or 'BasicUpgrade' and override default values using a hashtable.

.PARAMETER Template
Specifies the template to use for generating the XML configuration. Available templates are 'FreshInstall', 
'InstallHAwithWindowsAuth', 'InstallAWE', and 'BasicUpgrade'.

.PARAMETER Overrides
Allows you to provide a hashtable of key-value pairs to override the default values specified in the selected template.

.EXAMPLE
PS C:\> New-SilentConfigXml -Template 'FreshInstall' -Overrides @{
    'Host' = @{
        'Info' = @{
            'Website' = @{
                'Port' = '443'
            }
        }
    }
}

This example generates an XML configuration file using the 'FreshInstall' template and overrides the 'Port' value for the 'Website' section.

.EXAMPLE
PS C:\> New-SilentConfigXml -Template 'InstallAWE'

This example generates an XML configuration file using the 'InstallAWE' template without any overrides.

.Link
Information on the XML templates

https://support.solarwinds.com/SuccessCenter/s/article/Run-the-SolarWinds-Orion-Installer-in-the-silent-mode?language=en_US#STEP1

.NOTES
Ryan Woolsey | Loop1 | ryan.woolsey@loop1.com

#>

[CmdletBinding(DefaultParameterSetName='Template')]
param (
    [Parameter(ParameterSetName='Template', Mandatory=$true, HelpMessage="Specify the template name.")]
    [ValidateSet('FreshInstall', 'InstallHAwithWindowsAuth', 'InstallAWE', 'BasicUpgrade')]
    [string]$Template,

    [Parameter(ParameterSetName='Overrides')]
    [Hashtable]$Overrides = @{}
)

# Define the templates and default values
$Templates = @{
    'FreshInstall' = @{

        InstallerConfiguration = @{
            InstallPath = 'C:\Program Files\SolarWinds\Orion'
            AdvancedInstallMode = 'True'
            SkipConfigurationWizardRun = 'False'
            # <!--  CW Error handling  -->
        }

        Host = @{
            Info = @{
                ReconfigureDatabase = 'true'
                ReconfigureWebsite = 'true'
                ReconfigureServices = 'true'
                ReconfigurePermissions = 'true'
                Database = @{
                    CreateNewDatabase = 'False' # Sets flag to create new database during CW
                    UseExistingSqlAccount = 'False'
                    UseSQLSecurity = 'true' # Enables SQL Server authentication
                    DatabaseName = 'SolarWindsOrion' # Orion database name
                    DatabasePath = ''
                    ServerName = '127.0.0.1' # SQL server name for silent config wizard, e.g.: localhost
                    InstanceName = '' # SQL instance name for silent config wizard
                    UserPassword = 'Password' # SQL account password, when you enabled UseSqlAuthentication
                    User = 'sa' # SQL account username, when you enabled UseSqlAuthentication
                    AccountType = 'ExistingSql' # Orion database account access type. Other possible values: ExistingSql, ExistingWindows
                    Account = 'SolarWindsOrionDatabaseUser' # Name of Orion database account, e.g.: SolarwindsOrionDatabaseUser
                    AccountPassword = 'a' # Password to Orion database account
                    NeedSQLServerSecurity = 'false'
                    NeedToChangeSAPassword = 'false'
                    AddServiceDependencies = 'false'
                    RemoveServiceDependencies = 'false'
                    FailureInfo = ''
                }
                Website = @{
                    Folder = 'C:\InetPub\SolarWinds'
                    Address = '(All Unassigned)'
                    Port = '80'
                    ApplicationName = 'SolarWinds NetPerfMon'
                    LaunchWebConsole = 'false'
                    ConfigurationSkipped_IISNotInstalled = 'false'
                    EnableWindowsLogin = 'true'
                }
                OrionLogConfiguration = @{
                    StorageConfig = @{
                        CreateNewDatabase = 'True'
                        UseSQLSecurity = 'true'
                        AccountType = 'NewSql'
                        UseExistingSqlAccount = 'False'
                        DatabaseName = 'SolarWindsOrionLog'
                        DatabasePath = ''
                        ServerName = '127.0.0.1'
                        InstanceName = ''
                        User = 'sa'
                        UserPassword = 'Password'
                        Account = 'SolarWindsOrionDatabaseUser'
                        AccountPassword = 'a'
                        NeedSQLServerSecurity = 'false'
                        NeedToChangeSAPassword = 'false'
                        SAPassword = ''
                        AddServiceDependencies = 'false'
                        RemoveServiceDependencies = 'false'
                        FailureInfo = ''
                    }
                }
                NetFlowConfiguration = @{
                    FlowStorageConfig = @{
                        CreateNewDatabase = 'True'
                        UseSQLSecurity = 'True'
                        UseExistingSqlAccount = 'False'
                        DatabaseName = 'SolarWindsFlowStorage'
                        DatabasePath = ''
                        ServerName = '127.0.0.1'
                        InstanceName = ''
                        UserPassword = 'Password1'
                        User = 'sa'
                        Account = 'SolarWindsNtaDatabaseUser'
                        AccountType = 'NewSql'
                        AccountPassword = '123'
                    }
                }
            }
        }

    }

    'InstallHAwithWindowsAuth' = @{

        InstallerConfiguration = @{
            'MainPollerHostname' = '1.1.1.1'
            'ServerType' = 'MainPoller'
            'IsStandby' = 'True'
            'WebConsoleUserName' = 'Admin' # Enter user name and password only for first installation of SE.
            'WebConsolePassword' = 'Password'
        }

        Host = @{
            Info = @{
                Database = @{
                    AccountType = 'ExistingWindows'
                    SqlServerAuthenticationType = 'WindowsAuthentication'
                }
            }
        }
    }

    'InstallAWE' = @{

        InstallerConfiguration = @{
            'MainPollerHostname' = '1.1.1.1'
            'ServerType' = 'AdditionalWebsite'
            'IsStandby' = 'false'
            'WebConsoleUserName' = 'Admin' # Enter user name and password only for first installation of SE.
            'WebConsolePassword' = 'Password'
        }
    }

    'BasicUpgrade' = @{
        InstallerConfiguration = @{
            SkipConfigurationWizardRun = 'False'
        }

        Host = @{
            Info = @{
                ReconfigureDatabase = 'true'
                ReconfigureWebsite = 'true'
                ReconfigureServices = 'true'
                ReconfigurePermissions = 'true'
            }
        }
    }
}

# Check if the specified template exists
if (-not $Templates.ContainsKey($Template)) {
    Write-Error "Template '$Template' not found. Available templates are: $($Templates.Keys -join ', ')"
    exit 1
}

# Override default values with provided values (if any)
$TemplateValues = $Templates[$Template].Clone()
$Overrides.Keys | ForEach-Object { $TemplateValues[$_] = $Overrides[$_] }

# Generate the XML
$xmlDoc = New-Object System.Xml.XmlDocument

# Create XML declaration
$declaration = $xmlDoc.CreateXmlDeclaration("1.0", "utf-8", $null)
$xmlDoc.AppendChild($declaration)

# Function to recursively process the template and add elements to XML
function Add-XmlElement($node, $template)
{
    foreach ($key in $template.Keys) {
        $childElement = $xmlDoc.CreateElement($key)

        if ($template[$key] -is [Hashtable]) {
            Add-XmlElement $childElement $template[$key]
        } else {
            $childElement.InnerText = $template[$key]
        }

        $node.AppendChild($childElement)
    }
}

# Create <SilentConfig> element and its children
$silentConfig = $xmlDoc.CreateElement("SilentConfig")
$xmlDoc.AppendChild($silentConfig)

Add-XmlElement $silentConfig $TemplateValues

# Create <Plugins> element and its children
$pluginsElement = $xmlDoc.CreateElement("Plugins")
$silentConfig.AppendChild($pluginsElement)

$plugin1 = $xmlDoc.CreateElement("Plugin")
$plugin1.SetAttribute("Assembly", "SolarWinds.ConfigurationWizard.Plugin.LogMgmt")
$plugin1.SetAttribute("FactoryType", "SolarWinds.ConfigurationWizard.Plugin.LogMgmt.SilentConfigureFactory")
$pluginsElement.AppendChild($plugin1)

$plugin2 = $xmlDoc.CreateElement("Plugin")
$plugin2.SetAttribute("Assembly", "SolarWinds.ConfigurationWizard.Plugin.NetFlow")
$plugin2.SetAttribute("FactoryType", "SolarWinds.ConfigurationWizard.Plugin.NetFlow.SilentMode.NetFlowSilentConfigureFactory")
$pluginsElement.AppendChild($plugin2)


# Generate the current date in the format yyyy-MM-dd
$currentDate = Get-Date -Format "yyyy-MM-dd"

# Generate a new GUID
$guid = [System.Guid]::NewGuid()

# Create the desired filename format
$filename = "SilentXML-$currentDate-$guid.xml"

# Save the XML to a file
$xmlFilePath = Join-Path $PSScriptRoot "$filename"
$xmlDoc.Save($xmlFilePath)

Write-Host "XML has been generated and saved to $xmlFilePath"
