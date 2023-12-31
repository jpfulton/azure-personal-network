# Requires a local ED25519 key
# Reference: ssh-keygen -t ed25519 -C "youremailhere@domain.com"

param (
  [string]$username, 
  [string]$hostname
)

# Get the public key file generated previously on your client
$authorizedKey = Get-Content -Path ~\.ssh\id_ed25519.pub

# Generate the PowerShell to be run remote that will copy the public key file generated previously on your client to the authorized_keys file on your server
$remotePowershell = "powershell New-Item -Force -ItemType Directory -Path ~\.ssh; Add-Content -Force -Path ~\.ssh\authorized_keys -Value '$authorizedKey'; Add-Content -Force -Path c:\ProgramData\ssh\administrators_authorized_keys -Value '$authorizedKey'"

# Get admin pass from environment variable
$password = $env:ADMIN_PASSWORD
if (!$password) {
  Write-Host "Unable to find admin password in environment variable. Exiting..."
  Exit 1
}

# Connect to your server and run the PowerShell using the $remotePowerShell variable
$env:SSHPASS="$password"
sshpass -e ssh -o StrictHostKeyChecking=accept-new ${username}@${hostname} $remotePowershell
$env:SSHPASS=""