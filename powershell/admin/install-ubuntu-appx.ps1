# Perform unattended installation of Ubuntu 22.04 LTS into the WSL
# Run using admin account

Import-Module Appx -UseWindowsPowerShell

$ProgressPreference = 'SilentlyContinue'

# Download Ubuntu 22.04 LTS app package and dependencies
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile ~/VCLibs.appx -UseBasicParsing
Add-AppxPackage -Path ~/VCLibs.appx

Invoke-WebRequest -Uri https://aka.ms/wslubuntu2204 -OutFile ~/Ubuntu2204.appx -UseBasicParsing
Add-AppxPackage -Path ~/Ubuntu2204.appx
