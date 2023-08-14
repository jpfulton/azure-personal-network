# Checkout personal repositories
Write-Host "Checking out personal repositories..."
Set-Location -Path ~\

mkdir repos
Set-Location -Path ~\repos

git clone https://github.com/jpfulton/net-sms-notifier-cli.git
git clone https://github.com/jpfulton/blog.git
git clone https://github.com/jpfulton/gatsby-remark-copy-button.git

# Set up personal git globals
Write-Host "Setting up git global settings..."
git config --global user.name "J. Patrick Fulton"
git config --global user.email jpatrick.fulton@gmail.com
git config --global commit.gpgsign true 
git config --global gpg.program "C:\Program Files (x86)\Gpg4win\..\GnuPG\bin\gpg.exe"

Write-Host "For manual GPG completion steps see:"
Write-Host "https://docs.github.com/en/authentication/managing-commit-signature-verification"