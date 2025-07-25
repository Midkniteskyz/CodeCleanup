function CheckAndEnableFTPRule {
    $ruleName = "File Transfer Program"
    $firewallRule = Get-NetFirewallRule | Where-Object { $_.DisplayName -eq $ruleName }

    if ($firewallRule -eq $null) {
        Write-Host "FTP rules not found. Creating and enabling the rule..."
        New-NetFirewallRule -DisplayName "$ruleName" -Description "$rulename" -Enabled True -Profile Private, Public -Direction Inbound -Action Allow -Protocol UDP -LocalPort 20,21,49152-65535 -Program "%SystemRoot%\system32\ftp.exe" -Service Any -EdgeTraversalPolicy Allow
        New-NetFirewallRule -DisplayName "$ruleName" -Description "$rulename" -Enabled True -Profile Private, Public -Direction Inbound -Action Allow -Protocol TCP -LocalPort 20,21,49152-65535 -Program "%SystemRoot%\system32\ftp.exe" -Service Any -EdgeTraversalPolicy Allow
        Write-Host "FTP rule created and enabled."
    }
    elseif ($firewallRule.Enabled -eq $false) {
        Write-Host "Enabling the existing FTP rule..."
        Set-NetFirewallRule -Name $ruleName -Enabled True
        Write-Host "FTP rule enabled."
    }
    else {
        Write-Host "FTP rule is already allowed and enabled."
    }
}

CheckAndEnableFTPRule
