[CmdletBinding()]
param (
    # Univeral Parameters
    [Parameter(Mandatory,
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
    [ValidateSet("MainPoller", "AdditionalPoller", "AdditionalWebsite", "HAPoller")]
    [string]$DocumentType,

    [Parameter(Mandatory,
        Position = 1,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
    [string]$MainPollerHostname,

    [Parameter(Mandatory,
        Position = 2,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
    [string]$WebConsoleUserName = "Admin",

    [Parameter(Mandatory,
        Position = 3,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
    [string]$WebConsolePassword = "Password",

    [Parameter(ValueFromPipeline)]
    [ValidateSet("WindowsAuthentication", "SqlAuthentication", "ActiveDirectoryIntegrated", "ActiveDirectoryPassword")]
    [string]$SQLServerAuthType = "WindowsAuthentication"
)


# Create a new XML document
$xmlDocument = New-Object System.Xml.XmlDocument

# Add the XML declaration at the top of the document
$declaration = $xmlDocument.CreateXmlDeclaration("1.0", "utf-8", $null)
$xmlDocument.AppendChild($declaration)

# Create the root element
$silentConfigElement = $xmlDocument.CreateElement("SilentConfig")
$xmlDocument.AppendChild($silentConfigElement)

# Create the <InstallerConfiguration> element
$installerConfigurationElement = $xmlDocument.CreateElement("InstallerConfiguration")
$silentConfigElement.AppendChild($installerConfigurationElement)

# Add child elements to <InstallerConfiguration>
$mainPollerHostnameElement = $xmlDocument.CreateElement("MainPollerHostname")
$mainPollerHostnameElement.InnerText = $MainPollerHostname
$installerConfigurationElement.AppendChild($mainPollerHostnameElement)

# Create the <Host> element
$hostElement = $xmlDocument.CreateElement("Host")
$silentConfigElement.AppendChild($hostElement)

# Create the <Info> element
$infoElement = $xmlDocument.CreateElement("Info")
$hostElement.AppendChild($infoElement)

# Create the <Database> element
$databaseElement = $xmlDocument.CreateElement("Database")
$infoElement.AppendChild($databaseElement)

# Create the <Website> element
$websiteElement = $xmlDocument.CreateElement("Website")
$infoElement.AppendChild($websiteElement)

# Based on the selected DocumentType, create the appropriate XML structure
switch ($DocumentType) {
    "MainPoller" {

    }

    "AdditionalPoller" {

        # Add child elements to <InstallerConfiguration>
        $mainPollerHostnameElement = $xmlDocument.CreateElement("MainPollerHostname")
        $mainPollerHostnameElement.InnerText = $MainPollerHostname
        $installerConfigurationElement.AppendChild($mainPollerHostnameElement)

        $serverTypeElement = $xmlDocument.CreateElement("ServerType")
        $serverTypeElement.InnerText = "MainPoller"
        $installerConfigurationElement.AppendChild($serverTypeElement)

        $isStandbyElement = $xmlDocument.CreateElement("IsStandby")
        $isStandbyElement.InnerText = "False"
        $installerConfigurationElement.AppendChild($isStandbyElement)

        $webConsoleUserNameElement = $xmlDocument.CreateElement("WebConsoleUserName")
        $webConsoleUserNameElement.InnerText = $WebConsoleUserName
        $installerConfigurationElement.AppendChild($webConsoleUserNameElement)

        $webConsolePasswordElement = $xmlDocument.CreateElement("WebConsolePassword")
        $webConsolePasswordElement.InnerText = $WebConsolePassword
        $installerConfigurationElement.AppendChild($webConsolePasswordElement)

        # Add child elements to <Database>
        $accountTypeElement = $xmlDocument.CreateElement("AccountType")
        $accountTypeElement.InnerText = "ExistingWindows"
        $databaseElement.AppendChild($accountTypeElement)

        $sqlServerAuthElement = $xmlDocument.CreateElement("SqlServerAuthenticationType")
        $sqlServerAuthElement.InnerText = "WindowsAuthentication"
        $databaseElement.AppendChild($sqlServerAuthElement)

    }

    "AdditionalWebsite" {

        $serverTypeElement = $xmlDocument.CreateElement("ServerType")
        $serverTypeElement.InnerText = "AdditionalWebsite"
        $installerConfigurationElement.AppendChild($serverTypeElement)

        $isStandbyElement = $xmlDocument.CreateElement("IsStandby")
        $isStandbyElement.InnerText = "false"
        $installerConfigurationElement.AppendChild($isStandbyElement)

        # Enter user name and password only for first installation of SE.
        $webConsoleUserNameElement = $xmlDocument.CreateElement("WebConsoleUserName")
        $webConsoleUserNameElement.InnerText = $WebConsoleUserName
        $installerConfigurationElement.AppendChild($webConsoleUserNameElement)

        $webConsolePasswordElement = $xmlDocument.CreateElement("WebConsolePassword")
        $webConsolePasswordElement.InnerText = $WebConsolePassword
        $installerConfigurationElement.AppendChild($webConsolePasswordElement)

    }

    "HAPoller" {

        # Add child elements to <InstallerConfiguration>
        $mainPollerHostnameElement = $xmlDocument.CreateElement("MainPollerHostname")
        $mainPollerHostnameElement.InnerText = $MainPollerHostname
        $installerConfigurationElement.AppendChild($mainPollerHostnameElement)

        $serverTypeElement = $xmlDocument.CreateElement("ServerType")
        $serverTypeElement.InnerText = "MainPoller"
        $installerConfigurationElement.AppendChild($serverTypeElement)

        $isStandbyElement = $xmlDocument.CreateElement("IsStandby")
        $isStandbyElement.InnerText = "True"
        $installerConfigurationElement.AppendChild($isStandbyElement)

        $webConsoleUserNameElement = $xmlDocument.CreateElement("WebConsoleUserName")
        $webConsoleUserNameElement.InnerText = $WebConsoleUserName
        $installerConfigurationElement.AppendChild($webConsoleUserNameElement)

        $webConsolePasswordElement = $xmlDocument.CreateElement("WebConsolePassword")
        $webConsolePasswordElement.InnerText = $WebConsolePassword
        $installerConfigurationElement.AppendChild($webConsolePasswordElement)

        # Add child elements to <Database>
        $accountTypeElement = $xmlDocument.CreateElement("AccountType")
        $accountTypeElement.InnerText = "ExistingWindows"
        $databaseElement.AppendChild($accountTypeElement)

        $sqlServerAuthElement = $xmlDocument.CreateElement("SqlServerAuthenticationType")
        $sqlServerAuthElement.InnerText = "WindowsAuthentication"
        $databaseElement.AppendChild($sqlServerAuthElement)
    }

    default {
        Write-Host "Invalid DocumentType. Please choose one of the following: MainPoller, AdditionalPoller, AdditionalWebsite, HAPoller"
        exit
    }
}

# Save the XML document to a file
$xmlFilePath = "C:\Users\Ryan.Woolsey\OneDrive - Loop1\Documents\vscode\SolarWinds\SilentInstaller\output.xml"
$xmlDocument.Save($xmlFilePath)

Write-Host "XML document created and saved to: $xmlFilePath"
