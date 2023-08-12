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

# Remove Store Version of WSL (doesn't work in remote PS sessions)
Write-Host "Removing store version WSL..."
$package = Get-AppxPackage -name "*WindowsSubsystemForLinux*"
if ($package) {
  Remove-AppxPackage -package $package
}

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

# create user account
Write-Host "Creating default user account..."
wsl -u root useradd -m "$username"
wsl -u root sh -c "echo `"${username}:${password}`" | chpasswd" # wrapped in sh -c to get the pipe to work
wsl -u root chsh -s /bin/bash "$username"
wsl -u root usermod -aG adm,cdrom,sudo,dip,plugdev "$username"

Write-Host "Setting default user account..."
ubuntu config --default-user "$username"
