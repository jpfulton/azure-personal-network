# Update WSL distro base packages

# Sleep until WSL networking comes up
$command = 'wget -q --spider https://google.com ; echo \"\$?\" ;'
$netCheck = (wsl -u root sh -c "$command")
while ($netCheck -ne '"0"') {
  Write-Host "WSL networking is still coming up. Sleeping for 15 seconds..."
  Start-Sleep -Seconds 15

  $netCheck = (wsl -u root sh -c "$command")
}
Write-Host "WSL networking as recovered. Moving on..."

# apt-get install -y isn't enough to be truly noninteractive
$env:DEBIAN_FRONTEND = "noninteractive"
$env:WSLENV += ":DEBIAN_FRONTEND"

# update Ubuntu base packages
Write-Host "Updating distribution packages..."
wsl -u root apt-get update
wsl -u root apt-get full-upgrade -y
wsl -u root apt-get autoremove -y
wsl -u root apt-get autoclean
wsl --shutdown  # instead of 'reboot'