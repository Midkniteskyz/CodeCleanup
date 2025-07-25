param (
    [Parameter(Mandatory=$true)]
    [string]$Template,

    [Hashtable]$Overrides = @{}
)

# Define the templates and default values
$Templates = @{
    'base' = @{
        'InstallerConfiguration.SkipConfigurationWizardRun' = 'False'
    }
    'host' = @{
        'Info.ReconfigureDatabase' = 'true'
        'Info.ReconfigureWebsite' = 'true'
        'Info.ReconfigureServices' = 'true'
        'Info.ReconfigurePermissions' = 'true'
        'Info.Database.CreateNewDatabase' = 'False'
        'Info.Database.UseSQLSecurity' = 'true'
        'Info.Database.UseExistingSqlAccount' = 'True'
        'Info.Database.DatabaseName' = 'SolarWindsOrion'
        'Info.Database.ServerName' = '127.0.0.1'
        'Info.Database.UserPassword' = 'Password'
        'Info.Database.User' = 'sa'
        'Info.Database.AccountType' = 'ExistingSql'
        'Info.Database.Account' = 'SolarWindsOrionDatabaseUser'
        'Info.Database.AccountPassword' = 'a'
        'Info.Database.NeedSQLServerSecurity' = 'false'
        'Info.Database.NeedToChangeSAPassword' = 'false'
        'Info.Database.SAPassword' = 'Password'
        'Info.Database.AddServiceDependencies' = 'false'
        'Info.Database.RemoveServiceDependencies' = 'false'
        'Info.Database.FailureInfo' = ''
        'Info.Website.Folder' = 'C:\InetPub\SolarWinds'
        'Info.Website.Address' = '(All Unassigned)'
        'Info.Website.Port' = '443'
        'Info.Website.EnableHTTPS' = 'true'
        'Info.Website.SkipHTTPBinding' = 'false'
        'Info.Website.CertificateHash' = 'environment specific'
        'Info.Website.CertificateName' = 'environment specific'
        'Info.Website.CertificateResolvableCN' = 'environment specific'
        'Info.Website.ApplicationName' = 'SolarWinds NetPerfMon'
        'Info.Website.LaunchWebConsole' = 'false'
        'Info.Website.ConfigurationSkipped_IISNotInstalled' = 'false'
        'Info.Website.EnableWindowsLogin' = 'true'
        'Info.OrionLogConfiguration.StorageConfig.CreateNewDatabase' = 'False'
        'Info.OrionLogConfiguration.StorageConfig.UseSQLSecurity' = 'true'
        'Info.OrionLogConfiguration.StorageConfig.UseExistingSqlAccount' = 'True'
        'Info.OrionLogConfiguration.StorageConfig.DatabaseName' = 'SolarWindsOrionLog'
        'Info.OrionLogConfiguration.StorageConfig.ServerName' = '127.0.0.1'
        'Info.OrionLogConfiguration.StorageConfig.UserPassword' = 'Password'
        'Info.OrionLogConfiguration.StorageConfig.User' = 'sa'
        'Info.OrionLogConfiguration.StorageConfig.AccountType' = 'ExistingSql'
        'Info.OrionLogConfiguration.StorageConfig.Account' = 'SolarWindsOrionDatabaseUser'
        'Info.OrionLogConfiguration.StorageConfig.AccountPassword' = 'a'
        'Info.OrionLogConfiguration.StorageConfig.NeedSQLServerSecurity' = 'false'
        'Info.OrionLogConfiguration.StorageConfig.NeedToChangeSAPassword' = 'false'
        'Info.OrionLogConfiguration.StorageConfig.SAPassword' = ''
        'Info.OrionLogConfiguration.StorageConfig.AddServiceDependencies' = 'false'
        'Info.OrionLogConfiguration.StorageConfig.RemoveServiceDependencies' = 'false'
        'Info.OrionLogConfiguration.StorageConfig.FailureInfo' = ''
        'Info.NetFlowConfiguration.FlowStorageConfig.CreateNewDatabase' = 'False'
        'Info.NetFlowConfiguration.FlowStorageConfig.UseSQLSecurity' = 'True'
        'Info.NetFlowConfiguration.FlowStorageConfig.UseExistingSqlAccount' = 'True'
        'Info.NetFlowConfiguration.FlowStorageConfig.DatabaseName' = 'SolarWindsFlowStorage'
        'Info.NetFlowConfiguration.FlowStorageConfig.ServerName' = '127.0.0.1'
        'Info.NetFlowConfiguration.FlowStorageConfig.UserPassword' = 'Password1'
        'Info.NetFlowConfiguration.FlowStorageConfig.User' = 'sa'
        'Info.NetFlowConfiguration.FlowStorageConfig.Account' = 'SolarWindsNtaDatabaseUser'
        'Info.NetFlowConfiguration.FlowStorageConfig.AccountType' = 'ExistingSql'
        'Info.NetFlowConfiguration.FlowStorageConfig.AccountPassword' = '123'
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

# Additional elements for the 'host' template
if ($Template -eq 'host') {
    $hostElement = $xmlDoc.CreateElement("Host")
    $root.AppendChild($hostElement)

    $infoElement = $xmlDoc.CreateElement("Info")
    $hostElement.AppendChild($infoElement)

    $infoElement.InnerXml = $TemplateValues['Info'] | ForEach-Object { "<$_>$($TemplateValues['Info'][$_])</$_>" }

    # Add OrionLogConfiguration
    $orionLogConfigElement = $xmlDoc.CreateElement("OrionLogConfiguration")
    $infoElement.AppendChild($orionLogConfigElement)

    $storageConfigElement = $xmlDoc.CreateElement("StorageConfig")
    $orionLogConfigElement.AppendChild($storageConfigElement)

    $TemplateValues['Info.OrionLogConfiguration.StorageConfig'] | ForEach-Object {
        $childElement = $xmlDoc.CreateElement($_)
        $childElement.InnerText = $TemplateValues['Info.OrionLogConfiguration.StorageConfig'][$_]
        $storageConfigElement.AppendChild($childElement)
    }

    # Add NetFlowConfiguration
    $netFlowConfigElement = $xmlDoc.CreateElement("NetFlowConfiguration")
    $infoElement.AppendChild($netFlowConfigElement)

    $flowStorageConfigElement = $xmlDoc.CreateElement("FlowStorageConfig")
    $netFlowConfigElement.AppendChild($flowStorageConfigElement)

    $TemplateValues['Info.NetFlowConfiguration.FlowStorageConfig'] | ForEach-Object {
        $childElement = $xmlDoc.CreateElement($_)
        $childElement.InnerText = $TemplateValues['Info.NetFlowConfiguration.FlowStorageConfig'][$_]
        $flowStorageConfigElement.AppendChild($childElement)
    }
}

# Create <Plugins> element and its children
$pluginsElement = $xmlDoc.CreateElement("Plugins")
$root.AppendChild($pluginsElement)

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
