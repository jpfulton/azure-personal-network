# Query for Azure Spot Instance Eviction events.
# Initiate graceful shutdown if found.

# constants
$ENDPOINT_IP="169.254.169.254"
$API_VERSION="2020-07-01"
$HEADERS=@{ "Metadata" = "true" }
$ENDPOINT_URL="http://${ENDPOINT_IP}/metadata/scheduledevents?api-version=${API_VERSION}"

function Add-ToLogFile () {
  param (
    [string]$Content
    )
  $LOG_FILE="$env:ProgramFiles\SpotEvictionQueryService\eviction-log.txt"
  $NOW=(Get-Date)
  
  $logLine="${NOW} - ${Content}"
  Add-Content -Path $LOG_FILE -Value $logLine
}

try {
  $ErrorActionPreference = 'Stop'

  Add-ToLogFile -Content "Calling Azure Metadata API endpoint..."
  $jsonOutput = Invoke-RestMethod -Method Get -Uri $ENDPOINT_URL -Headers $HEADERS | ConvertTo-Json -Depth 64
  $output = ConvertFrom-Json -InputObject $jsonOutput

  if ($output.Events.Length -gt 0) {
    Add-ToLogFile -Content "Azure event(s) found... Looking for Preempt events..."

    foreach($event in $output.Events) {
      if ($event.EventType -eq "Preempt") {
        Add-ToLogFile -Content "Preempt event found. Starting graceful shutdown..."

        # Send SMS notification to administrators
        Add-ToLogFile -Content "Sending SMS notifications."
        $smsJob = Start-Job -ScriptBlock { 
          $NOTIFIER_CLI="C:\Users\jpfulton\AppData\Local\Yarn\bin\sms-notify-cli.cmd"
          $HOSTNAME=$(hostname)
          & $NOTIFIER_CLI eviction $HOSTNAME 
        }

        # Message logged in users
        Add-ToLogFile -Content "Messaging logged in users."
        $msgJob = Start-Job -ScriptBlock { 
          msg * /time:3 "Azure spot instance eviction detected. Graceful shutdown starting..." 
        }

        # Write eviction discovery to system event log
        Add-ToLogFile -Content "Writing to event log."
        $eventLogJob = Start-Job -ScriptBlock {
          Write-EventLog `
          -EventId 100 `
          -LogName "Application" `
          -Source "Azure Spot Instance Eviction Service" `
          -EntryType Warning `
          -Message "Azure eviction event discovered. Starting gracecful shutdown..."
        }

        # wait on background jobs
        Add-ToLogFile -Content "Waiting on background tasks."
        Wait-Job -Job @($smsJob, $msgJob, $eventLogJob)

        # Initiate shutdown
        Add-ToLogFile -Content "Background tasks complete. Shutting down..."
        Stop-Computer -Force
      }
    }
  }
}
catch {
  Exit 1
}
finally {
  $ErrorActionPreference = 'Continue'
}