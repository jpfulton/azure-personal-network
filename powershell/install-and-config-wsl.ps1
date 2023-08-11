C:\Users\jpfulton\AppData\Local\Microsoft\WindowsApps\ubuntu.exe install --root

$username = "ubuntu"
$password = "ubuntu"

# create user account
wsl -u root useradd -m "$username"
wsl -u root sh -c "echo `"${username}:${password}`" | chpasswd" # wrapped in sh -c to get the pipe to work
wsl -u root chsh -s /bin/bash "$username"
wsl -u root usermod -aG adm,cdrom,sudo,dip,plugdev "$username"

C:\Users\jpfulton\AppData\Local\Microsoft\WindowsApps\ubuntu.exe config --default-user "$username"

# apt install -y isn't enough to be truly noninteractive
$env:DEBIAN_FRONTEND = "noninteractive"
$env:WSLENV += ":DEBIAN_FRONTEND"

# update Ubuntu base packages
wsl -u root apt update
wsl -u root apt full-upgrade -y
wsl -u root apt autoremove -y
wsl -u root apt autoclean
wsl --shutdown  # instead of 'reboot'
