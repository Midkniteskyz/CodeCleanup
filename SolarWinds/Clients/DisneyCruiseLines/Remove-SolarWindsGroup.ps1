function Remove-SolarWindsGroup {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = "Enter one or more hostnames for the SolarWinds server(s)."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('ComputerName', 'Server')]
        [string[]]$Hostname,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = "Enter the username for the SWIS connection.",
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('User')]
        [string]$Username,

        [Parameter(
            Mandatory = $true,
            Position = 2,
            HelpMessage = "Enter the password for the SWIS connection.",
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Pass')]
        [string]$Password,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [int[]]$IDNumber
    )

    Begin{
        # Create connection parameters
        $swisParams = @{
            Hostname = $currentHost
            Username = $Username
            Password = $Password
        }

        # Attempt to connect to SWIS
        try {
            Write-Host "Connecting to $currentHost..." -ForegroundColor Yellow
            $swis = Connect-Swis @swisParams
            Write-Host "Successfully connected to $currentHost" -ForegroundColor Green
            Write-Verbose "SWIS connection established to $currentHost"
        }
        catch {
            Write-Error "Failed to connect to $currentHost. Error: $_"
            continue # Skip to next host if connection fails
        }
    }

    Process {
        foreach ($id in $IDNumber) {
            if ($PSCmdlet.ShouldProcess("Group ID: $id", "Remove")) {
                try {
                    # Invoke the SWIS API to delete the specified container
                    Write-Verbose "Deleting group with ID: $id"
                    Invoke-SwisVerb $Swis "Orion.Container" "DeleteContainer" @($id) | Out-Null
                    Write-Output "Deleted group with ID: $id"
                }
                catch {
                    Write-Error "Failed to delete group with ID $id : $($_.Exception.Message)"
                }
            }
        }
    }
}
