$logPath = "C:\ProgramData\SolarWinds\InformationService\v3.0\Orion.InformationService.log"

# Define the regex pattern to detect user logins (WindowsIdentity retrieval)
$loginPattern = '^(?<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d+).*?Successfully retrieved WindowsIdentity for user (?<username>[\w\\\-]+)'

# Parse and extract login events
$logins = Select-String -Path $logPath -Pattern $loginPattern | ForEach-Object {
    if ($_ -match $loginPattern) {
        [PSCustomObject]@{
            Timestamp = $matches['timestamp']
            Username  = $matches['username']
            LogPath   = $_.Path
        }
    }
}

# Display in an interactive table
$logins | Sort-Object Timestamp # | Out-GridView -Title "SWIS User Logins"
