[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [Hashtable]$override
)

# Create XML Document
$xmlDoc = New-Object System.Xml.XmlDocument

# Create Root Element <SilentConfig>
$silentConfigElement = $xmlDoc.CreateElement("SilentConfig")
$xmlDoc.AppendChild($silentConfigElement)

# Define a table
$FullConfig = [ordered]@{
    #region InstallerConfiguration
    InstallerConfiguration =  @{
        SkipConfigurationWizardRun = 'False'
    }
    #endregion InstallerConfiguration

    #region Host
    Host =  [ordered]@{
        Info = [ordered]@{
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

# Function to construct the XML document recursively
function CreateXmlElement {
    param (
        [System.Xml.XmlDocument]$xmlDoc,
        [System.Xml.XmlElement]$parentElement,
        [Hashtable]$config
    )

    foreach ($key in $config.Keys) {
        $value = $config[$key]

        # Create Element
        $element = $xmlDoc.CreateElement($key)

        if ($value -is [Hashtable]) {
            # Recursively call the function for nested Hashtable
            CreateXmlElement $xmlDoc $element $value
        } else {
            # Set the element's value
            $element.InnerText = $value
        }

        # Append the element to the parent
        $parentElement.AppendChild($element)
    }
}

# $override = @{SilentConfig = @{InstallerConfiguration = @{SkipConfigurationWizardRun = 'IMNEW'}}}

# Update the configuration with the override values
if ($override) {
    foreach ($key in $override.Keys) {
        $value = $override[$key]
        $keyParts = $key -split '\.'
        $currentConfig = $FullConfig

        # Traverse through the nested properties to get to the correct level
        for ($i = 0; $i -lt $keyParts.Length - 1; $i++) {
            $currentConfig = $currentConfig[$keyParts[$i]]
        }

        # Update the value
        $currentConfig[$keyParts[-1]] = $value
    }
}

# Loop through the table and construct the XML document
foreach ($config in $FullConfig.GetEnumerator()) {
    $level1ElementName = $config.Key
    $level1ElementValue = $config.Value

    # Create Level 1 Element
    $level1Element = $xmlDoc.CreateElement($level1ElementName)
    $silentConfigElement.AppendChild($level1Element)

    # Call the function to construct the XML recursively for Level 2 and beyond
    CreateXmlElement $xmlDoc $level1Element $level1ElementValue
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

Write-Host "XML document has been generated and saved to $xmlFilePath"
