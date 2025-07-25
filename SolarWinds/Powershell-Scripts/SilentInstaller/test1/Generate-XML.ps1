param (
    [Parameter(Mandatory=$true)]
    [string]$Template,

    [Hashtable]$Overrides = @{}
)

# Define the templates and default values
$Templates = @{
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

# Additional elements for the 'host' template
$Templates['host'] = @{
    'Database.AccountType' = 'ExistingWindows'
    'Database.SqlServerAuthenticationType' = 'WindowsAuthentication'
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

    $databaseElement = $xmlDoc.CreateElement("Database")
    $infoElement.AppendChild($databaseElement)

    foreach ($key in $TemplateValues.Keys) {
        if ($key -like 'Database.*') {
            $subKey = $key -replace '^Database\.', ''
            $childElement = $xmlDoc.CreateElement($subKey)
            $childElement.InnerText = $TemplateValues[$key]
            $databaseElement.AppendChild($childElement)
        }
    }
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
