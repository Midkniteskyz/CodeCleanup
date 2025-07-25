$watcherSubscriber = Get-EventSubscriber | Where-Object { $_.SourceObject -like "*FileSystemWatcher*" }

if ($watcherSubscriber -ne $null) {
    Unregister-Event -SubscriptionId $watcherSubscriber.SubscriptionId
    Write-Host "FileSystemWatcher event subscriber stopped."
} else {
    Write-Host "FileSystemWatcher event subscriber not found."
}
