# Install Yarn Package Manager

#$corepack = "C:\Program Files\nodejs\corepack.cmd"
#& $corepack enable
#& $corepack prepare yarn@stable --activate

$npm = "C:\Program Files\nodejs\npm.cmd"
& $npm install -g yarn

Write-Host "Yarn installed at version:"
Write-Host (yarn --version)