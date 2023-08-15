# Query for Azure Spot Instance Eviction events.
# Initiate graceful shutdown if found.

# constants
$ENDPOINT_IP="169.254.169.254"
$API_VERSION="2020-07-01"
$HEADERS=@{ "Metadata" = "true" }
$ENDPOINT_URL="http://${ENDPOINT_IP}/metadata/scheduledevents?api-version=${API_VERSION}"

$NOTIFIER_CLI="C:\Users\jpfulton\AppData\Local\Yarn\bin\sms-notify-cli.cmd"
$HOSTNAME=$(hostname)

Write-Host "Calling Azure Metadata API endpoint..."
$jsonOutput = Invoke-RestMethod -Method Get -Uri $ENDPOINT_URL -Headers $HEADERS | ConvertFrom-Json -Depth 64
$output = ConvertFrom-Json -InputObject $jsonOutput

if ($output.Events.Length -gt 0) {
  Write-Host "Azure event(s) found... Looking for Preempt events..."

  foreach($event in $output.Events) {
    if ($event.EventType -eq "Preempt") {
      Write-Host "Preempt event found. Starting graceful shutdown..."

      # Write eviction discovery to system event log
      Write-EventLog `
        -EventId 100 `
        -LogName "Application" `
        -Source "Azure Spot Instance Eviction Service" `
        -EntryType Warning `
        -Message "Azure eviction event discovered. Starting gracecful shutdown..."

      # Message logged in users
      msg * "Azure spot instance eviction detected. Gracefull shutdown starting..."

      # Send SMS notification to administrators
      & $NOTIFIER_CLI eviction $HOSTNAME

      # Sleep for 5 seconds
      Start-Sleep 5

      # Initiate shutdown
      Stop-Computer -Force
    }
  }
}