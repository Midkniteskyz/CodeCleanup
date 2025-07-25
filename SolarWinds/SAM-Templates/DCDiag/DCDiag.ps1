# Initialize variables for SolarWinds SAM
$ComponentStatus = 0  # Status (0 = OK, 1 = Warning, 2 = Critical)
$Output = @()
$service = $args[0] # The service to test for, passed in from the script arguments
$server = "${Node.Sysname}"

# Run the dcdiag command to test the service
try {

        $dcdiagOutput = Invoke-Command -ComputerName $server -ScriptBlock {param($s) dcdiag /test:$s} -Credential ${Credential} -ArgumentList $service

        # Check the output for success or failure
        if ($dcdiagOutput -match "passed test $service") {
            $ComponentStatus = 0  # OK
            $Output += "Message: $service test passed."
        } elseif ($dcdiagOutput -match "failed test $service") {
            if ($dcdiagOutput -match "Access is denied.") {
                $ComponentStatus = 1  # Critical
                $Output += "Message: $service test failed.Access is denied."
            } else {
                $ComponentStatus = 2  # Critical
                $Output += "Message: $service test failed."
            }
        } else {
            $ComponentStatus = 1  # Warning
            $Output += "Message: $service test output unclear. Review manually."
        }

} catch {
    # Handle errors
    $ComponentStatus = 2  # Critical
    $Output += "Message: An error occurred while running dcdiag: $($_.Exception.Message)"
}

# Write the results in the format expected by SolarWinds SAM
Write-Host $Output
Write-Host "Statistic: $ComponentStatus"

# Exit with the appropriate status for SAM
exit $ComponentStatus