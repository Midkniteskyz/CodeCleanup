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

function Parse-XmlNode {
    param (
        [System.Xml.XmlNode]$Node,
        [int]$Indent = 0
    )

    $indentStr = ' ' * ($Indent * 2)

    # Handle encoded XML in Configuration elements (SolarWinds specific)
    if ($Node.Name -eq "Configuration" -and $Node.InnerText -match "&lt;") {
        Write-Host "$indentStr<$($Node.Name)>" -ForegroundColor Cyan
        Write-Host "$indentStr  [Encoded XML - Decoding and parsing...]" -ForegroundColor Yellow
        
        try {
            $decodedXml = [System.Net.WebUtility]::HtmlDecode($Node.InnerText)
            [xml]$nestedXml = $decodedXml
            Parse-XmlNode -Node $nestedXml.DocumentElement -Indent ($Indent + 1)
        } catch {
            Write-Host "$indentStr  [Failed to parse nested XML: $($_.Exception.Message)]" -ForegroundColor Red
            Write-Host "$indentStr  Raw content: $($Node.InnerText.Substring(0, [Math]::Min(100, $Node.InnerText.Length)))..." -ForegroundColor Gray
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
    } else {
        Write-Warning "XML document has no root element"
    }
}
catch {
    Write-Error "Failed to parse XML: $($_.Exception.Message)"
    Write-Verbose "Full exception: $($_.Exception | Format-List * | Out-String)"
    exit 1
}