# Enable systemd in /etc/wsl.conf
Write-Host "Enabling systemd in Ubuntu on WSL host..."
wsl -u root sh -c "echo `[boot]\n  systemd=true\n` > /etc/wsl.conf"
wsl --shutdown
wsl -u root sleep 5

# Update WSL from web download to support systemd
Write-Host "Updating WSL from web download..."
wsl --update --web-download