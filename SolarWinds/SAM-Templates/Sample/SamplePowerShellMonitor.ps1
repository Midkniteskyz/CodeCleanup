function Start-MainFunction {
    [CmdletBinding()]
    param (
        [string]$MachineName = $env:COMPUTERNAME  # Default to the current machine name
    )

    begin {
        # Initial output for script start
        Write-Host "Message.Begin: Script is running on: $MachineName"
        Write-Host "Statistic.Begin: 0"  # Initial success message
    }

    process {
        try {
            # Placeholder for your main code logic
            # Example: Testing a simple command
            $testCommand = Get-Date  # Replace this with your actual command
            Write-Host "Message.Process1: Test Command Output: $testCommand"
            Write-Host "Statistic.Process1: 0"  # Indicate ongoing success

            # More working code can be added here...

            # If everything runs successfully
            Write-Host "Message.Process2: Script completed successfully."
            Write-Host "Statistic.Process2: 0"  # Indicate success in SAM
            exit 0  # Exit with code 0 for success

        } catch {
            # Handle any errors that occurred during execution
            Write-Host "Message.ProcessFail: An error occurred while executing the script. $_" # Outputs the error message
            Write-Host "Statistic.ProcessFail: 1"  # Indicate failure in SAM
            exit 1  # Exit with code 1 for failure
        }
    }

    end {
        # Any cleanup code can go here if needed
        Write-Host "Message.End: Script execution finished."
        Write-Host "Statistic.End: 0"  # Indicate that the script has finished execution
    }
}

# Call the function
Start-MainFunction
