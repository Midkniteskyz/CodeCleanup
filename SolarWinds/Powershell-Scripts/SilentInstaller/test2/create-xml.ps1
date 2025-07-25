param (
    [Parameter(Mandatory=$true)]
    [string]$Template,

    [Hashtable]$Overrides = @{}
)

# Define the templates and default values
$Templates = @{
    'FullConfigDefault' = @{
    #region InstallerConfiguration
    InstallerConfiguration =  @{
        SkipConfigurationWizardRun = 'False'
    }
    #endregion InstallerConfiguration

    #region Host
    Host =  @{
        Info = @{
            ReconfigureDatabase = 'true'
            ReconfigureWebsite = 'true'
            ReconfigureServices = 'true'
            ReconfigurePermissions = 'true'
            Database = @{
                CreateNewDatabase = 'False'
                UseSQLSecurity = 'true'
                UseExistingSqlAccount = 'True'
                DatabaseName = 'SolarWindsOrion'
                ServerName = '127.0.0.1'
                UserPassword = 'Password'
                User = 'sa'
                AccountType = 'ExistingSql'
                Account = 'SolarWindsOrionDatabaseUser'
                AccountPassword = 'a'
                NeedSQLServerSecurity = 'false'
                NeedToChangeSAPassword = 'false'
                SAPassword = 'Password'
                AddServiceDependencies = 'false'
                RemoveServiceDependencies = 'false'
                FailureInfo = ''
            }
            Website = @{
                Folder = 'C:\InetPub\SolarWinds'
                Address = '(All Unassigned)'
                Port = '443'
                EnableHTTPS = 'true'
                SkipHTTPBinding = 'false'
                CertificateHash = 'environment specific'
                CertificateName = 'environment specific'
                CertificateResolvableCN = 'environment specific'
                ApplicationName = 'SolarWinds NetPerfMon'
                LaunchWebConsole = 'false'
                ConfigurationSkipped_IISNotInstalled = 'false'
                EnableWindowsLogin = 'true'
            }
            OrionLogConfiguration = @{
                StorageConfig = @{
                    CreateNewDatabase = 'False'
                    UseSQLSecurity = 'true'
                    UseExistingSqlAccount = 'True'
                    DatabaseName = 'SolarWindsOrionLog'
                    ServerName = '127.0.0.1'
                    UserPassword = 'Password'
                    User = 'sa'
                    AccountType = 'ExistingSql'
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
                    CreateNewDatabase = 'False'
                    UseSQLSecurity = 'True'
                    UseExistingSqlAccount = 'True'
                    DatabaseName = 'SolarWindsFlowStorage'
                    ServerName = '127.0.0.1'
                    UserPassword = 'Password1'
                    User = 'sa'
                    Account = 'SolarWindsNtaDatabaseUser'
                    AccountType = 'ExistingSql'
                    AccountPassword = '123'
                }
            }
        }
    }
    #endregion Host

    #region Plugins
    Plugins =  @{
        Plugin1 = @{
            Assembly = 'SolarWinds.ConfigurationWizard.Plugin.LogMgmt'
            FactoryType = 'SolarWinds.ConfigurationWizard.Plugin.LogMgmt.SilentConfigureFactory'
        }
        Plugin2 = @{
            Assembly = 'SolarWinds.ConfigurationWizard.Plugin.NetFlow'
            FactoryType = 'SolarWinds.ConfigurationWizard.Plugin.NetFlow.SilentMode.NetFlowSilentConfigureFactory'
        }
    }
    #endregion Plugins

    }

    'website' = @{
        'MainPollerHostname' = '1.1.1.1'
        'ServerType' = 'AdditionalWebsite'
        'IsStandby' = 'false'
        'WebConsoleUserName' = 'Admin'
        'WebConsolePassword' = 'Password'
    }
    'upgrade' = @{
        'SkipConfigurationWizardRun' = 'False'
    }
    # Add more templates here as needed
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

# Create root element <SilentConfig>
$root = $xmlDoc.CreateElement("SilentConfig")
$xmlDoc.AppendChild($root)

# Create <InstallerConfiguration> element and its children
$installerConfig = $xmlDoc.CreateElement("InstallerConfiguration")
$root.AppendChild($installerConfig)

foreach ($key in $TemplateValues.Keys) {
    $childElement = $xmlDoc.CreateElement($key)
    $childElement.InnerText = $TemplateValues[$key]
    $installerConfig.AppendChild($childElement)
}

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
