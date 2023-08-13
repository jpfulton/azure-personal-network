# Checkout personal repositories
Write-Host "Checking out personal repositories..."
Set-Location -Path ~\

mkdir repos
Set-Location -Path ~\repos

git clone https://github.com/jpfulton/net-sms-notifier-cli.git
git clone https://github.com/jpfulton/blog.git
git clone https://github.com/jpfulton/gatsby-remark-copy-button.git
