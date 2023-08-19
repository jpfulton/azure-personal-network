$ProgressPreference = 'SilentlyContinue'
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

# Install PSWindowsUpdate module and dependencies
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module PSWindowsUpdate -Force

# Add Microsoft Update Servers
# Same a "Give me updates for other Microsoft products when I update Windows" checkbox
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false

# Get all available updates and install
Get-WindowsUpdate -AcceptAll -Install

# Reboot as needed
Get-WURebootStatus -Confirm:$false
