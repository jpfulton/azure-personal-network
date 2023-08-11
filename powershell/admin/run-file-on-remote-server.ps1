# Shell to execute a passed PS script on a remote server via SSH to Remote PS environment

param (
  [string]$username, 
  [string]$hostname, 
  [string]$remotescript
)

$session = New-PSSession -UserName $username -HostName $hostname
$output = Invoke-Command -Session $session -FilePath $remotescript

Write-Host "Remote command output:"
$output
