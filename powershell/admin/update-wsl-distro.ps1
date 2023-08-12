# Update WSL distro base packages

# Sleep until WSL networking comes up
$command = 'wget -q --spider https://google.com ; echo \"\$?\" ;'
$netCheck = (wsl -u root sh -c "$command")
while ($netCheck -ne '"0"') {
  Write-Host "WSL networking is still coming up. Sleeping for 15 seconds..."
  Start-Sleep -Seconds 15

  $netCheck = (wsl -u root sh -c "$command")
}
Write-Host "WSL networking has recovered. Moving on..."

# apt-get install -y isn't enough to be truly noninteractive
$env:DEBIAN_FRONTEND = "noninteractive"
$env:WSLENV += ":DEBIAN_FRONTEND"

# update Ubuntu base packages
Write-Host "Updating distribution packages..."
Write-Host (wsl -u root sh -c 'apt-get update && apt-get full-upgrade -y')
Write-Host (wsl --shutdown)  # instead of 'reboot'

Write-Host "Bringing the distribution back up with updates installed..."
Write-Host (wsl -u root sleep 5) # bring the distro back up with updates installed