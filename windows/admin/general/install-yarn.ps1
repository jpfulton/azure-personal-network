# Install Yarn Package Manager
choco install -y --no-progress yarn

Write-Host "Yarn installed at version:"
Write-Host (yarn --version)