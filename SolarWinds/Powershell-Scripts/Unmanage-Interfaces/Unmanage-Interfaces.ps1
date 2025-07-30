<#
Script Purpose: Gather a filtered list of interfaces based on custom properties, 
then set those interfaces to unmanaged or managed.

Author: Improved version
Date: $(Get-Date -Format "yyyy-MM-dd")
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OrionServer,
    
    [Parameter(Mandatory = $false)]
    [string]$OrionUserName,
    
    [Parameter(Mandatory = $false)]
    [SecureString]$OrionPassword
)

function Connect-ToOrion {
    param(
        [string]$Server,
        [string]$Username,
        [SecureString]$Password
    )
    
    try {
        if (-not $Server) {
            $Server = Read-Host "Enter the Orion Server hostname or IP"
        }
        
        if (-not $Username) {
            $Username = Read-Host "Enter the Username"
        }
        
        if (-not $Password) {
            $Password = Read-Host "Enter the Password" -AsSecureString
        }
        
        # Convert SecureString to plain text for SolarWinds connection
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        )
        
        Write-Host "Connecting to Orion server..." -ForegroundColor Green
        $swis = Connect-Swis -Hostname $Server -Username $Username -Password $PlainPassword
        
        # Clear password from memory
        $PlainPassword = $null
        [System.GC]::Collect()
        
        return $swis
    }
    catch {
        Write-Error "Failed to connect to Orion server: $($_.Exception.Message)"
        exit 1
    }
}

function Get-InterfaceCustomProperties {
    param($SwisConnection)
    
    $query = @'
SELECT Field, DataType, MaxLength, Description, TargetEntity, URI
FROM Orion.CustomProperty
WHERE TargetEntity = 'Orion.NPM.InterfacesCustomProperties'
'@
    
    try {
        return Get-SwisData -SwisConnection $SwisConnection -Query $query
    }
    catch {
        Write-Error "Failed to retrieve custom properties: $($_.Exception.Message)"
        return $null
    }
}

function Select-CustomProperty {
    param($CustomProperties)

    do {
        Write-Host "`nAvailable Interface Custom Properties:" -ForegroundColor Cyan

        $CustomProperties | Select-Object Field, Description | Format-Table -AutoSize | Out-Host

        Start-Sleep -Milliseconds 100
        
        $selectedField = Read-Host "Which Field would you like to filter interfaces on?"

        if ($selectedField -notin $CustomProperties.Field) {
            Write-Warning "Please enter a valid field name from the list above."
        }
    } while ($selectedField -notin $CustomProperties.Field)

    Write-Host "Selected custom property: $selectedField" -ForegroundColor Green
    return $selectedField
}

function Get-CustomPropertyValues {
    param(
        $SwisConnection,
        [string]$FieldName
    )
    
    $query = @"
SELECT DISTINCT $FieldName
FROM Orion.NPM.InterfacesCustomProperties
WHERE $FieldName IS NOT NULL
ORDER BY $FieldName
"@
    
    try {
        return Get-SwisData -SwisConnection $SwisConnection -Query $query
    }
    catch {
        Write-Error "Failed to retrieve custom property values: $($_.Exception.Message)"
        return $null
    }
}

function Select-PropertyValue {
    param(
        [array]$Values,
        [string]$FieldName
    )
    
    do {
        Write-Host "`nAvailable values for '$FieldName':" -ForegroundColor Cyan
        for ($i = 0; $i -lt $Values.Count; $i++) {
            Write-Host "[$($i + 1)] $($Values[$i])"
        }
        
        $selection = Read-Host "Enter the number or exact value you want to filter by"
        
        # Check if it's a number selection
        if ($selection -match '^\d+$') {
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $Values.Count) {
                $selectedValue = $Values[$index]
                break
            }
        }
        # Check if it's an exact match
        elseif ($selection -in $Values) {
            $selectedValue = $selection
            break
        }
        
        Write-Warning "Please enter a valid selection."
    } while ($true)
    
    Write-Host "Selected value: $selectedValue" -ForegroundColor Green
    return $selectedValue
}

function Get-FilteredInterfaces {
    param(
        $SwisConnection,
        [string]$FieldName,
        [string]$FieldValue
    )
    
    $query = @"
SELECT 
    icp.Interface.Node.Caption as [Node],
    icp.Interface.Caption as [Interface Caption],
    icp.Interface.IfName as [Interface Name],
    icp.$FieldName as [$FieldName],
    icp.Interface.URI as [URI],
    icp.Interface.InterfaceID as [InterfaceID],
    icp.Interface.UnManaged as [Unmanaged],
    icp.Interface.UnManageFrom as [UnManageFrom],
    icp.Interface.UnManageUntil as [UnManageUntil]
FROM Orion.NPM.InterfacesCustomProperties as icp
WHERE icp.$FieldName = '$FieldValue'
ORDER BY icp.Interface.Node.Caption, icp.Interface.Caption
"@
    
    try {
        return Get-SwisData -SwisConnection $SwisConnection -Query $query
    }
    catch {
        Write-Error "Failed to retrieve filtered interfaces: $($_.Exception.Message)"
        return $null
    }
}

function Set-InterfaceManagementState {
    param(
        $SwisConnection,
        [array]$Interfaces,
        [string]$Action,
        [DateTime]$UnmanageTime = [DateTime]::Now.ToUniversalTime(),
        [DateTime]$RemanageTime = [DateTime]::Now.AddHours(1).ToUniversalTime()
    )
    
    $successCount = 0
    $errorCount = 0
    
    foreach ($interface in $Interfaces) {
        try {
            # Create the netObjectId from InterfaceID (format: I:InterfaceID)
            $netObjectId = "I:$($interface.InterfaceID)"

            switch ($Action.ToLower()) {
                'unmanage' {
                    Write-Host "Setting interface '$($interface.'Interface Caption')' on node '$($interface.Node)' to unmanaged..." -ForegroundColor Yellow
                    
                    # Use the correct Orion.NPM.Interfaces Unmanage verb with proper parameters
                    $arguments = @(
                        $netObjectId,           # netObjectId
                        [DateTime]$UnmanageTime.ToString("yyyy-MM-ddTHH:mm:ss.fff"),          # unmanageTime  
                        [DateTime]$RemanageTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fff"),          # remanageTime
                        $false                  # isRelative
                    )
                    
                    Invoke-SwisVerb -SwisConnection $SwisConnection -EntityName "Orion.NPM.Interfaces" -Verb "Unmanage" -Arguments $arguments
                }
                'manage' {
                    Write-Host "Setting interface '$($interface.'Interface Caption')' on node '$($interface.Node)' to managed..." -ForegroundColor Yellow
                    
                    # Use the Remanage verb for interfaces
                    Invoke-SwisVerb -SwisConnection $SwisConnection -EntityName "Orion.NPM.Interfaces" -Verb "Remanage" -Arguments @($netObjectId)
                }
            }
            $successCount++
        }
        catch {
            Write-Error "Failed to $Action interface '$($interface.'Interface Caption')': $($_.Exception.Message)"
            $errorCount++
        }
    }
    
    Write-Host "`nOperation completed:" -ForegroundColor Green
    Write-Host "  Successful: $successCount" -ForegroundColor Green
    Write-Host "  Errors: $errorCount" -ForegroundColor Red
}

# Main Script Execution
try {
    Write-Host "=== Orion Interface Management Script ===" -ForegroundColor Cyan

    # Connect to Orion
    $swis = Connect-ToOrion -Server $OrionServer -Username $OrionUserName -Password $OrionPassword

    # Get available custom properties
    Write-Host "Retrieving interface custom properties..." -ForegroundColor Green
    $customProperties = Get-InterfaceCustomProperties -SwisConnection $swis

    if (-not $customProperties) {
        Write-Error "No custom properties found. Exiting."
        exit 1
    }

    # Select custom property to filter on
    $selectedField = Select-CustomProperty -CustomProperties $customProperties

    # Get possible values for the selected custom property
    Write-Host "Retrieving possible values for '$selectedField'..." -ForegroundColor Green
    $propertyValues = Get-CustomPropertyValues -SwisConnection $swis -FieldName $selectedField

    if (-not $propertyValues) {
        Write-Error "No values found for custom property '$selectedField'. Exiting."
        exit 1
    }

    # Select value to filter by
    $selectedValue = Select-PropertyValue -Values $propertyValues -FieldName $selectedField

    # Get filtered interfaces
    Write-Host "Retrieving interfaces with $selectedField = '$selectedValue'..." -ForegroundColor Green
    $filteredInterfaces = Get-FilteredInterfaces -SwisConnection $swis -FieldName $selectedField -FieldValue $selectedValue
    
    if (-not $filteredInterfaces -or $filteredInterfaces.Count -eq 0) {
        Write-Warning "No interfaces found matching the criteria."
        exit 0
    }
    
    # Display results
    Write-Host "`nFound $($filteredInterfaces.Count) interface(s):" -ForegroundColor Cyan
    $filteredInterfaces | Select-Object Node, 'Interface Caption', 'Interface Name', $selectedField, Unmanaged | Format-Table -AutoSize
    
    # Ask user what action to take
    do {
        Write-Host "`nWhat would you like to do with these interfaces?" -ForegroundColor Cyan
        Write-Host "[1] Set to Unmanaged"
        Write-Host "[2] Set to Managed"
        Write-Host "[3] Exit without changes"
        
        $actionChoice = Read-Host "Enter your choice (1-3)"
        
        switch ($actionChoice) {
            '1' { 
                # Ask for unmanage duration
                Write-Host "`nUnmanage duration options:" -ForegroundColor Cyan
                Write-Host "[1] 1 hour"
                Write-Host "[2] 4 hours" 
                Write-Host "[3] 24 hours"
                Write-Host "[4] 1 week"
                Write-Host "[5] Custom duration"
                Write-Host "[6] Indefinite (until manually managed)"
                
do {
    $durationChoice = Read-Host "Select duration (1-5)"
    $remanageTime = switch ($durationChoice) {
        '1' { [DateTime]::Now.AddHours(1); break }
        '2' { [DateTime]::Now.AddHours(4); break }
        '3' { [DateTime]::Now.AddDays(1); break }
        '4' { [DateTime]::Now.AddDays(7); break }
        '5' { 
            do {
                $customDuration = Read-Host "Enter duration in hours"
                if ($customDuration -match '^\d+$' -and [int]$customDuration -gt 0) {
                    $remanageTime = [DateTime]::Now.AddHours([int]$customDuration)
                    break
                } else {
                    Write-Warning "Please enter a valid number of hours."
                }
            } while ($true)
            $remanageTime
            break
        }
        '6' { [DateTime]'9999-01-01T00:00:00' }  # Indefinite, no remanage time
        default { $null }
    }
} while ($null -eq $remanageTime)
                
            $confirmation = Read-Host "Are you sure you want to UNMANAGE $($filteredInterfaces.Count) interface(s) until $($remanageTime.ToString('yyyy-MM-dd HH:mm'))? (y/N)"
            if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
                Set-InterfaceManagementState -SwisConnection $swis -Interfaces $filteredInterfaces -Action 'unmanage' -RemanageTime $remanageTime
                $validChoice = $true
            }
            else {
                Write-Host "Operation cancelled." -ForegroundColor Yellow
                $validChoice = $true
            }
        }
        '2' { 
            $confirmation = Read-Host "Are you sure you want to MANAGE $($filteredInterfaces.Count) interface(s)? (y/N)"
            if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
                Set-InterfaceManagementState -SwisConnection $swis -Interfaces $filteredInterfaces -Action 'manage'
                $validChoice = $true
            }
            else {
                Write-Host "Operation cancelled." -ForegroundColor Yellow
                $validChoice = $true
            }
        }
        '3' { 
            Write-Host "Exiting without making changes." -ForegroundColor Yellow
            $validChoice = $true
        }
        default { 
            Write-Warning "Please enter 1, 2, or 3."
            $validChoice = $false
        }
    }
} while (-not $validChoice)
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Write-Host "`nScript completed." -ForegroundColor Green
}