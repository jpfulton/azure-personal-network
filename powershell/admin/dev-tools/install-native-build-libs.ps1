# Install the Visual C++ Redistributable library
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "$env:TEMP\vc_redist.x64.exe"

Write-Host "Installing the Visual C++ Redistributable library..."
Start-Process -Wait "$env:TEMP\vc_redist.x64.exe" -ArgumentList /Q
