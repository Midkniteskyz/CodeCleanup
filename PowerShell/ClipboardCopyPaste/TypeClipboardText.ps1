# Auto-Type-Clipboard.ps1
# 
# Purpose: Automatically types out clipboard content character by character
# Use Case: Useful for bypassing paste restrictions in applications or simulating human typing
# 
# Requirements: Windows PowerShell with .NET Framework
# Usage: Copy text to clipboard, run this script, switch to target application within 5 seconds
#
# Author: PowerShell Script
# Version: 1.1

# Give user time to switch to the target application window
Write-Host "Starting in 5 seconds... Switch to your target application window now!"
Start-Sleep -Seconds 5

# Load necessary .NET assemblies for Windows Forms functionality
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

<#
.SYNOPSIS
    Escapes special characters and simulates human-like typing
.DESCRIPTION
    Takes input text and sends each character individually using SendKeys,
    with special character escaping to ensure proper input handling
.PARAMETER text
    The text string to be typed out character by character
#>
function Send-Keys {
    param (
        [Parameter(Mandatory=$true)]
        [string]$text
    )

    # Escape special characters that have meaning in SendKeys
    # These characters need to be wrapped in braces to be treated as literals
    $text = $text.Replace("+", "{+}")    # Plus sign (Shift modifier)
    $text = $text.Replace("^", "{^}")    # Caret (Ctrl modifier)  
    $text = $text.Replace("%", "{%}")    # Percent (Alt modifier)
    $text = $text.Replace("~", "{~}")    # Tilde (Enter key)
    $text = $text.Replace("(", "{(}")    # Left parenthesis
    $text = $text.Replace(")", "{)}")    # Right parenthesis
    $text = $text.Replace("[", "{[}")    # Left square bracket
    $text = $text.Replace("]", "{]}")    # Right square bracket
    $text = $text.Replace("{", "{{}")    # Left curly brace
    $text = $text.Replace("}", "{}}")    # Right curly brace

    # Convert string to character array for individual processing
    $chars = $text.ToCharArray()
    $totalChars = $chars.Length
    $currentChar = 0

    Write-Host "Typing $totalChars characters..."

    # Process each character individually to simulate human typing
    foreach ($char in $chars) {
        try {
            # Send the keystroke and wait for it to be processed
            [System.Windows.Forms.SendKeys]::SendWait($char)
            
            # Small delay between keystrokes to simulate realistic typing speed
            # Adjust this value to make typing faster (lower) or slower (higher)
            Start-Sleep -Milliseconds 25
            
            $currentChar++
            
            # Show progress every 50 characters to avoid console spam
            if ($currentChar % 50 -eq 0) {
                Write-Host "Progress: $currentChar/$totalChars characters typed"
            }
        }
        catch {
            Write-Warning "Failed to send character: $char. Error: $($_.Exception.Message)"
        }
    }
    
    Write-Host "Typing completed! $totalChars characters sent."
}

# Main execution block
try {
    # Attempt to retrieve text from the Windows clipboard
    $clipboardText = [System.Windows.Forms.Clipboard]::GetText()

    # Check if clipboard contains text data
    if ($clipboardText -and $clipboardText.Trim() -ne "") {
        Write-Host "Clipboard text found ($($clipboardText.Length) characters). Starting to type..."
        Write-Host "Preview (first 100 chars): $($clipboardText.Substring(0, [Math]::Min(100, $clipboardText.Length)))"
        
        # Execute the typing function
        Send-Keys -text $clipboardText
        
        Write-Host "Script completed successfully!"
    } 
    else {
        Write-Warning "No text found in clipboard or clipboard is empty."
        Write-Host "Please copy some text to the clipboard and run the script again."
    }
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    Write-Host "Make sure you have the necessary permissions and .NET Framework is available."
}

# Pause to show final message
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")