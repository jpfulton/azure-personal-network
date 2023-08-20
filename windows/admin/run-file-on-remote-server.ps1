# Shell to execute a passed PS script on a remote server via SSH to Remote PS environment

param (
  [string]$username, 
  [string]$hostname, 
  [string]$remotescript
)

$retryCount = 0

Write-Host "Establishing remote session..."
$session = New-PSSession -UserName $username -HostName $hostname
while (!$session -and ($retryCount -le 18)) {
  $retryCount += 1

  Write-Host "On retry number ($retryCount). Retrying session creation in 10 seconds..."
  Start-Sleep -Seconds 10
  $session = New-PSSession -UserName $username -HostName $hostname
}

if ($session) { 
  Write-Host "Session established. Executing command..."
  $output = Invoke-Command -Session $session -FilePath $remotescript
}
else {
  Write-Host "Unable to establish session after retry attempts. Exiting with error code..."
  Exit 1
}

Write-Host "Remote command output:"
$output
