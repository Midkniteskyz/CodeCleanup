<#
.SYNOPSIS
Creates a local administrator account on specified servers with a randomly generated password.

.DESCRIPTION
This script automates the process of creating a local administrator account on specified servers. 
It generates a random password for the account, sets it to never expire, and adds the account to the local Administrators group.
The details of the created accounts (server name and password) are exported to a CSV file for reference.

.PARAMETER servers
An array of server names where the local administrator account will be created. Default is set to "L1SAPE" and "L1SARM".

.PARAMETER username
The username of the local administrator account to be created. Default is "Loop1admin".

.PARAMETER passwordLength
The length of the randomly generated password. Default is set to 12 characters.

.EXAMPLE
.\CreateLocalAdminAccount.ps1
Creates a local administrator account on the specified servers with a randomly generated password.

#>

# Import the ActiveDirectory module
Import-Module ActiveDirectory

# Define the servers to create the account on
$servers = @("L1SAPE", "L1SARM")

# Initialize an empty array to store the results
$result = @()

# Loop through the servers
$result = foreach ($server in $servers) {
    
    Invoke-Command -ComputerName $server -ScriptBlock {

        $hostname = $env:Computername

        # Randomize passwords
        function Get-RandomPassword {
            Param(
                [Parameter(Mandatory = $true)]
                [int]$Length
            )
            Begin {
                if ($Length -lt 4) {
                    End
                }
                $Numbers = 1..9
                $LettersLower = 'abcdefghijklmnopqrstuvwxyz'.ToCharArray()
                $LettersUpper = 'ABCEDEFHIJKLMNOPQRSTUVWXYZ'.ToCharArray()
                $Special = '!@#$%^&*()=+[{}]/?<>'.ToCharArray()

                # For the 4 character types (upper, lower, numerical, and special)
                $N_Count = [math]::Round($Length * .2)
                $L_Count = [math]::Round($Length * .4)
                $U_Count = [math]::Round($Length * .2)
                $S_Count = [math]::Round($Length * .2)
            }
            Process {
                $Pswrd = $LettersLower | Get-Random -Count $L_Count
                $Pswrd += $Numbers | Get-Random -Count $N_Count
                $Pswrd += $LettersUpper | Get-Random -Count $U_Count
                $Pswrd += $Special | Get-Random -Count $S_Count

                # If the password length isn't long enough (due to rounding), add special characters
                if ($Pswrd.length -lt $Length) {
                    $Pswrd += $Special | Get-Random -Count ($Length - $Pswrd.length)
                }

                # Randomize the order of characters in the password
                $Pswrd = ($Pswrd | Get-Random -Count $Length) -join ""
            }
            End {
                $Pswrd
            }
        }

        # Generate a random password
        $password = Get-RandomPassword -Length 12
        
        # Define the local admin username
        $username = "Loop1admin"

        # Convert the password to a SecureString
        $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
        
        # Create the new local user account
        New-LocalUser -Name $username -Password $securePassword -FullName "Local Administrator" -Description "Auto created local admin" -PasswordNeverExpires
        
        # Add the new user to the Administrators group
        Add-LocalGroupMember -Group "Administrators" -Member $username
          
        # Create output object with server name and password
        $output = [pscustomobject]@{
            Server = $hostname
            Password = $password
        }
        
        # Return the result
        $output
    }
}

# Export the results to a CSV file
$result | Export-Csv -Path "C:\Scripts\LocalAdminPW.csv" -NoTypeInformation

# Clean up sessions (if applicable)
# Remove-PSSession $session
