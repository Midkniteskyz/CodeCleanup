function Convert-HashtableToXml {
    param(
        [hashtable]$Hashtable,
        [System.Xml.XmlElement]$ParentElement
    )

    $XmlDocument = $ParentElement.OwnerDocument

    foreach ($key in $Hashtable.Keys) {
        $value = $Hashtable[$key]

        $element = $XmlDocument.CreateElement($key)

        if ($value -is [hashtable]) {
            Convert-HashtableToXml -Hashtable $value -ParentElement $element
        } else {
            $element.InnerText = $value
        }

        $ParentElement.AppendChild($element)
    }
}

# Create an XML document
$xmlDocument = New-Object System.Xml.XmlDocument

# Define the root element
$rootElement = $xmlDocument.CreateElement('Task')
$rootElement.SetAttribute('version', '1.4')
$rootElement.SetAttribute('xmlns', 'http://schemas.microsoft.com/windows/2004/02/mit/task')

# Append the root element to the XML document
$xmlDocument.AppendChild($rootElement)

# Define the hashtable structure
$Hashtable = @{
    'RegistrationInfo' = @{
        'Date' = '2023-08-10T11:40:59.223005'
        'Author' = ''
        'Description' = 'Start the FTP Transfer script task'
        'URI' = '\FTPTask'
    }
    'Principals' = @{
        'Principal' = @{
            'id' = 'Author'
            'LogonType' = 'InteractiveToken'
            'RunLevel' = 'HighestAvailable'
        }
    }
    # ... other elements ...
}

# Convert the hashtable to XML and append it to the root element
Convert-HashtableToXml -Hashtable $Hashtable -ParentElement $rootElement 

# Get the XML content as a string
$xmlContent = $xmlDocument.OuterXml

# Output the XML content
$xmlContent

# Output the XML content
#$xmlDocument.Save("C:\Path\To\Output\File.xml")
