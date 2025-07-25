param (
    [Parameter(Mandatory = $true)]
    [string]$XmlInput
)

function Get-XmlContent {
    param ([string]$xmlInput)
    
    Write-Verbose "Testing input: '$xmlInput'"
    
    # First check if it's a file path
    if ($xmlInput -and (Test-Path -Path $xmlInput -ErrorAction SilentlyContinue)) {
        Write-Verbose "Input is a valid file path"
        $content = Get-Content -Path $xmlInput -Raw -ErrorAction Stop
        
        if ([string]::IsNullOrWhiteSpace($content)) {
            throw "File exists but is empty or contains only whitespace: $xmlInput"
        }
        
        try {
            return [xml]$content
        } catch {
            throw "File contains invalid XML: $($_.Exception.Message)"
        }
    } 
    # Check if it looks like XML content
    elseif ($xmlInput -and $xmlInput.Trim().StartsWith('<')) {
        Write-Verbose "Input appears to be raw XML"
        try {
            return [xml]$xmlInput
        } catch {
            throw "Invalid XML string provided: $($_.Exception.Message)"
        }
    } 
    else {
        throw "Input must be a valid file path or raw XML string. Received: '$xmlInput'"
    }
}

function Extract-ConfigurationContent {
    param (
        [System.Xml.XmlDocument]$XmlDoc
    )
    
    Write-Host "`nConfiguration Content Analysis:" -ForegroundColor Yellow
    Write-Host "==============================" -ForegroundColor Yellow
    
    # Create namespace manager to handle namespaced elements
    $nsManager = New-Object System.Xml.XmlNamespaceManager($XmlDoc.NameTable)
    $nsManager.AddNamespace("def", "http://schemas.datacontract.org/2004/07/SolarWinds.Orion.Core.Models.Alerting")
    
    # Try multiple ways to find Configuration nodes
    $configNodes = $XmlDoc.SelectNodes("//Configuration")
    if (-not $configNodes -or $configNodes.Count -eq 0) {
        $configNodes = $XmlDoc.SelectNodes("//def:Configuration", $nsManager)
    }
    if (-not $configNodes -or $configNodes.Count -eq 0) {
        # Fallback: search by element name regardless of namespace
        $configNodes = $XmlDoc.GetElementsByTagName("Configuration")
    }
    
    if (-not $configNodes -or $configNodes.Count -eq 0) {
        Write-Host "No Configuration nodes found." -ForegroundColor Red
        return
    }
    
    foreach ($configNode in $configNodes) {
        Write-Host "`nConfiguration Node:" -ForegroundColor Cyan
        Write-Host "  Node Type: $($configNode.NodeType)" -ForegroundColor Gray
        Write-Host "  Has Child Nodes: $($configNode.HasChildNodes)" -ForegroundColor Gray
        Write-Host "  Child Count: $($configNode.ChildNodes.Count)" -ForegroundColor Gray
        
        # Check if content is HTML-encoded
        if ($configNode.InnerText -match "&lt;") {
            Write-Host "  Type: HTML-encoded XML" -ForegroundColor Yellow
            try {
                $decodedXml = [System.Net.WebUtility]::HtmlDecode($configNode.InnerText)
                Write-Host "  Decoded XML:" -ForegroundColor Green
                
                # Format the XML for better readability
                $xmlDoc = New-Object System.Xml.XmlDocument
                $xmlDoc.LoadXml($decodedXml)
                
                $stringWriter = New-Object System.IO.StringWriter
                $xmlWriter = New-Object System.Xml.XmlTextWriter($stringWriter)
                $xmlWriter.Formatting = [System.Xml.Formatting]::Indented
                $xmlWriter.Indentation = 2
                $xmlDoc.WriteContentTo($xmlWriter)
                
                $formattedXml = $stringWriter.ToString()
                Write-Host "$formattedXml" -ForegroundColor White
                
            } catch {
                Write-Host "  Failed to decode XML: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "  Raw content:" -ForegroundColor Gray
                Write-Host "  $($configNode.InnerText)" -ForegroundColor Gray
            }
        }
        # Direct XML content
        elseif ($configNode.HasChildNodes -and ($configNode.ChildNodes | Where-Object { $_.NodeType -eq 'Element' })) {
            Write-Host "  Type: Direct XML content" -ForegroundColor Yellow
            
            try {
                $stringWriter = New-Object System.IO.StringWriter
                $xmlWriter = New-Object System.Xml.XmlTextWriter($stringWriter)
                $xmlWriter.Formatting = [System.Xml.Formatting]::Indented
                $xmlWriter.Indentation = 2
                
                # Write each child element
                foreach ($child in $configNode.ChildNodes) {
                    if ($child.NodeType -eq 'Element') {
                        $child.WriteTo($xmlWriter)
                    }
                }
                
                $xmlWriter.Close()
                $formattedXml = $stringWriter.ToString()
                Write-Host "  Formatted XML:" -ForegroundColor Green
                Write-Host "$formattedXml" -ForegroundColor White
                
            } catch {
                Write-Host "  Failed to format XML: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "  Inner XML:" -ForegroundColor Gray
                Write-Host "  $($configNode.InnerXml)" -ForegroundColor Gray
            }
        }
        # Plain text
        else {
            Write-Host "  Type: Plain text" -ForegroundColor Yellow
            Write-Host "  Content: $($configNode.InnerText)" -ForegroundColor White
        }
    }
}

function Parse-XmlNode {
    param (
        [System.Xml.XmlNode]$Node,
        [int]$Indent = 0
    )

    $indentStr = ' ' * ($Indent * 2)

    # Handle Configuration elements (SolarWinds specific) - both encoded and direct XML
    if ($Node.Name -eq "Configuration") {
        Write-Host "$indentStr<$($Node.Name)>" -ForegroundColor Cyan
        
        # Check if content is HTML-encoded
        if ($Node.InnerText -match "&lt;") {
            Write-Host "$indentStr  [HTML-encoded XML detected - Decoding...]" -ForegroundColor Yellow
            try {
                $decodedXml = [System.Net.WebUtility]::HtmlDecode($Node.InnerText)
                [xml]$nestedXml = $decodedXml
                Parse-XmlNode -Node $nestedXml.DocumentElement -Indent ($Indent + 1)
            } catch {
                Write-Host "$indentStr  [Failed to parse nested XML: $($_.Exception.Message)]" -ForegroundColor Red
                Write-Host "$indentStr  Raw content: $($Node.InnerText.Substring(0, [Math]::Min(200, $Node.InnerText.Length)))..." -ForegroundColor Gray
            }
        }
        # Check if it contains direct XML (child elements)
        elseif ($Node.HasChildNodes -and ($Node.ChildNodes | Where-Object { $_.NodeType -eq 'Element' })) {
            Write-Host "$indentStr  [Direct XML content found - Parsing...]" -ForegroundColor Yellow
            foreach ($child in $Node.ChildNodes) {
                if ($child.NodeType -eq 'Element') {
                    Parse-XmlNode -Node $child -Indent ($Indent + 1)
                }
            }
        }
        # Plain text content
        else {
            $text = $Node.InnerText.Trim()
            if (-not [string]::IsNullOrEmpty($text)) {
                Write-Host "$indentStr  $text" -ForegroundColor White
            }
        }
        
        Write-Host "$indentStr</$($Node.Name)>" -ForegroundColor Cyan
        return
    }

    # Print opening tag
    Write-Host "$indentStr<$($Node.Name)>" -ForegroundColor Green

    # Display attributes
    if ($Node.Attributes -and $Node.Attributes.Count -gt 0) {
        foreach ($attr in $Node.Attributes) {
            Write-Host "$indentStr  @$($attr.Name) = '$($attr.Value)'" -ForegroundColor Magenta
        }
    }

    # Handle text content more robustly
    $hasElementChildren = $Node.ChildNodes | Where-Object { $_.NodeType -eq 'Element' }
    $textNodes = $Node.ChildNodes | Where-Object { $_.NodeType -eq 'Text' -and -not [string]::IsNullOrWhiteSpace($_.Value) }
    
    if ($textNodes -and -not $hasElementChildren) {
        # Pure text content
        $combinedText = ($textNodes | ForEach-Object { $_.Value }) -join ''
        Write-Host "$indentStr  $combinedText" -ForegroundColor White
    } elseif ($textNodes -and $hasElementChildren) {
        # Mixed content - show text nodes separately
        foreach ($textNode in $textNodes) {
            Write-Host "$indentStr  [Text]: $($textNode.Value.Trim())" -ForegroundColor Gray
        }
    }

    # Recurse into child elements
    foreach ($child in $Node.ChildNodes) {
        if ($child.NodeType -eq 'Element') {
            Parse-XmlNode -Node $child -Indent ($Indent + 1)
        }
    }

    # Print closing tag
    Write-Host "$indentStr</$($Node.Name)>" -ForegroundColor Green
}

# MAIN EXECUTION
try {
    Write-Verbose "Starting XML parsing with input: '$XmlInput'"
    $xmlDoc = Get-XmlContent -xmlInput $XmlInput

    Write-Host "XML Document Structure:" -ForegroundColor Yellow
    Write-Host "======================" -ForegroundColor Yellow
    
    # Display basic document info
    if ($xmlDoc.DocumentElement) {
        Write-Host "Root Element: $($xmlDoc.DocumentElement.Name)" -ForegroundColor Cyan
        if ($xmlDoc.DocumentElement.NamespaceURI) {
            Write-Host "Namespace: $($xmlDoc.DocumentElement.NamespaceURI)" -ForegroundColor Cyan
        }
        Write-Host ""
        
        # Parse the document
        Parse-XmlNode -Node $xmlDoc.DocumentElement
        
        # Extract and display Configuration content separately
        Extract-ConfigurationContent -XmlDoc $xmlDoc
    } else {
        Write-Warning "XML document has no root element"
    }
}
catch {
    Write-Error "Failed to parse XML: $($_.Exception.Message)"
    Write-Verbose "Full exception: $($_.Exception | Format-List * | Out-String)"
    exit 1
}