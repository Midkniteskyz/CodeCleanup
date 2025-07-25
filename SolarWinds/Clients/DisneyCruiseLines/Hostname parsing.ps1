# Assuming you have already connected to the SolarWinds Information Service (SWIS)
$swisParams = @{
    Hostname = 'dclwdrsolarw01'
    UserName = 'loop1'
    Password = '30DayPassword!'
    ErrorAction = 'Stop'
}
$swis = Connect-Swis @swisParams

function Get-FloorNumberFromCaption {
    param (
        [Parameter(Mandatory = $true)]
        $SwisConnection
    )
    
    # Query to get captions
    $query = "SELECT NodeID, Caption, Sysname FROM Orion.Nodes WHERE Caption LIKE '%[0-9][0-9][0-9]%'"
    $nodes = Get-SwisData $swis $query
    
    # Regex to find exactly three consecutive digits
    # $regex = '\b(\d{3})\b' # \b is a word boundary, ensuring digits are isolated
    # $regex = '(\d{3})(?!\d)'
    $regex = '(?<!\d)(\d{3})(?!\d)'
    
    # Iterate through each node and extract digits
    $extractedDigits = foreach ($node in $nodes) {
        if ($node.Caption -match $regex) {
            # Capture and output the digits
            [PSCustomObject]@{
                NodeID = $node.NodeID
                Caption = $node.Caption
                SystemName = $node.Sysname
                ExtractedDigits = $matches[1] # $matches[1] refers to the first capture group
            }
        }
    }
    
    # Extract the first digit of each number, ensure uniqueness, and sort them
    $uniqueFirstDigits = $extractedDigits.ExtractedDigits | ForEach-Object {
        # Convert the number to a string and get the first character
        $_.ToString().Substring(0,1)
    } | Sort-Object -Unique
    
    # Display the unique first digits
    # $uniqueFirstDigits

}
