# Create a WScript.Shell object
$shell = New-Object -ComObject WScript.Shell

# Execute the script in the background
$command = 'cscript.exe //Nologo C:\Windows\System32\slmgr.vbs /dlv All'
$output = $shell.Exec($command)

# Read the output
$results = $output.StdOut.ReadAll()

# Initialize an array to store license objects
$licenses = @()

# Split the results into lines
$lines = $results -split "`r?`n"

# Initialize a hashtable for the current license being processed
$currentLicense = @{}

# Loop through each line to extract license information
foreach ($line in $lines) {
    # Check for key-value pairs
    if ($line -match "^(.*?):\s*(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $currentLicense[$key] = $value
    } elseif ($line -match "^\s*$") {
        # If a blank line is encountered, it indicates the end of the current license block
        if ($currentLicense.Count -gt 0) {
            # Create a custom object and add it to the array
            $licenses += [pscustomobject]$currentLicense
            # Reset the hashtable for the next license
            $currentLicense = @{}
        }
    }
}

# Check for any remaining license info if the last line wasn't blank
if ($currentLicense.Count -gt 0) {
    $licenses += [pscustomobject]$currentLicense
}

# Output the license information
# $licenses | Format-List

# Example: Accessing specific information from the custom objects
foreach ($license in $licenses) {

    if ($license.'License Status' -eq 'Licensed') {
        Write-Host "License Name: $($license.Description) - Status: $($license.'License Status')"
    }
}
