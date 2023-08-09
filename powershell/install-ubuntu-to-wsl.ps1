# Perform unattended installation of Ubuntu 22.04 LTS into the WSL

# Update WSL kernel
wsl --update

# Download Ubuntu 22.04 LTS app package and dependencies
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile ~/VCLibs.appx -UseBasicParsing
Add-AppxPackage -Path ~/VCLibs.appx

Invoke-WebRequest -Uri https://aka.ms/wslubuntu2204 -OutFile ~/Ubuntu.appx -UseBasicParsing 
Add-AppxPackage -Path ~/Ubuntu.appx

# Refresh the path variable
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

ubuntu2204 install --root

$username = "ubuntu"
$password = "ubuntu"

# create user account
wsl -u root useradd -m "$username"
wsl -u root sh -c "echo `"${username}:${password}`" | chpasswd" # wrapped in sh -c to get the pipe to work
wsl -u root  chsh -s /bin/bash "$username"
wsl -u root usermod -aG adm,cdrom,sudo,dip,plugdev "$username"

ubuntu2204 config --default-user "$username"

# apt install -y isn't enough to be truly noninteractive
$env:DEBIAN_FRONTEND = "noninteractive"
$env:WSLENV += ":DEBIAN_FRONTEND"

# update Ubuntu base packages
wsl -u root apt update
wsl -u root apt full-upgrade -y
wsl -u root apt autoremove -y
wsl -u root apt autoclean
wsl --shutdown  # instead of 'reboot'
