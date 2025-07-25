#Args : HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\,DisableWindowsUpdateAccess,1

param( 
     [string]$reg, 
     [string]$Key,
     $target_value 
) 

$reg_value = Get-ItemProperty $reg -name $Key

Write-Host "Message: '$reg' is currently set to '$reg_value'" 

if ($reg_value -match "$key=$target_value") { 
     Write-Host "Statistic: 0" 
} else { 
     Write-Host "Statistic: 1" 
} 

Exit 0 

# Define the remote machine name
$remoteMachine = "RemoteMachineName"  # Replace with the actual remote machine name
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion"  # Specify the registry path

# Use Invoke-Command to access the remote registry
Invoke-Command -ComputerName $remoteMachine -ScriptBlock {
    param($path)

    # Get registry items from the specified path
    Get-ChildItem -Path $path | Select-Object PSChildName, Property
} -ArgumentList $registryPath
