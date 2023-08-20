# Helper function for MSI installs
# Functions have to be inline for remote execution
function Install-Msi {
  param(
      $File
  )

  $DataStamp = get-date -Format yyyyMMddTHHmmss
  $logFile = '{0}-{1}.log' -f $File.fullname,$DataStamp
  $MSIArguments = @(
      "/i"
      ('"{0}"' -f $File.fullname)
      "/qn"
      "/norestart"
      "/L*v"
      $logFile
  )
  Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow 
}

$ProgressPreference = 'SilentlyContinue'

Import-Module Appx -UseWindowsPowerShell

# Update WSL Kernel (avoid store)
Write-Host "Install WSL kernel version from MSI..."
Invoke-WebRequest -Uri https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -OutFile ~/wsl_update_x64.msi -UseBasicParsing
$msiFile = Get-ChildItem -Path ~/wsl_update_x64.msi
Install-Msi -File $msiFile

# Set WSL 2 as default
Write-Host "Setting WSL 2 as default version..."
wsl --set-default-version 2

# Download Ubuntu 22.04 LTS app package and dependencies
Write-Host "Downloading Ubuntu 22.04 LTS package and dependencies..."
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile ~/VCLibs.appx -UseBasicParsing
Add-AppxPackage -Path ~/VCLibs.appx

Invoke-WebRequest -Uri https://aka.ms/wslubuntu2204 -OutFile ~/Ubuntu2204.appx -UseBasicParsing
Add-AppxPackage -Path ~/Ubuntu2204.appx

# Install Ubuntu distribution
Write-Host "Installing Ubuntu 22.04 LTS distribution into WSL..."
ubuntu install --root

$username = "ubuntu"
$password = "ubuntu"

# apt-get install -y isn't enough to be truly noninteractive
$env:DEBIAN_FRONTEND = "noninteractive"
$env:WSLENV += ":DEBIAN_FRONTEND"

# update Ubuntu base packages
Write-Host "Updating distribution packages..."
ubuntu run apt-get update
ubuntu run apt-get full-upgrade -y

# Enable systemd in /etc/wsl.conf
Write-Host "Enabling systemd in Ubuntu on WSL host..."
ubuntu run "echo ""[boot]"" > /etc/wsl.conf"
ubuntu run "echo ""systemd=true"" >> /etc/wsl.conf"

# create user account
Write-Host "Creating default user account..."
ubuntu run useradd -m "$username"
ubuntu run "echo ""${username}:${password}""  | chpasswd"
ubuntu run chsh -s /bin/bash "$username"
ubuntu run usermod -aG adm,cdrom,sudo,dip,plugdev "$username"

Write-Host "Setting default user account..."
ubuntu config --default-user "$username"

# Update WSL from web download to support systemd
Write-Host "Updating WSL from web download..."
wsl --update --web-download
