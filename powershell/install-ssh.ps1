# Helper function for MSI installations
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

# Download and Install Powershell Environment
Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.3.6/PowerShell-7.3.6-win-x64.msi -OutFile ~/powershell.msi -UseBasicParsing
$msiFile = Get-ChildItem -Path ~/powershell.msi
Install-Msi -File $msiFile

# Install the OpenSSH Client
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Install the OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start the sshd service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
}

# Add Powershell Subsystem and Public Key Auth to sshd_config
$sshdConfigFile = Get-ChildItem -Path $env:ProgramData/ssh/sshd_config
$subSystemLine = "Subsystem powershell c:/progra~1/powershell/7/pwsh.exe -sshs -nologo"
$pubKeyAuthLine = "PubkeyAuthentication yes"
@($subSystemLine) + (Get-Content $sshdConfigFile.FullName) | Set-Content $sshdConfigFile.FullName
@($pubKeyAuthLine) + (Get-Content $sshdConfigFile.FullName) | Set-Content $sshdConfigFile.FullName

# Create and configure administrators_authorized_keys file
# with permissions that sshd will accept
$authorizedKeyFile = "c:\ProgramData\ssh\administrators_authorized_keys"
New-Item -Path $authorizedKeyFile -ItemType file -Force

$NewAcl = Get-Acl -Path $authorizedKeyFile

# disable permission inheritance
$NewAcl.SetAccessRuleProtection($true, $false)

# Set properties for SYSTEM
$identity = "SYSTEM"
$fileSystemRights = "FullControl"
$type = "Allow"
# Create new rule
$fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
$fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
# Apply new rule
$NewAcl.SetAccessRule($fileSystemAccessRule)

# Set properties for administrators
$identity = "BUILTIN\Administrators"
$fileSystemRights = "FullControl"
$type = "Allow"
# Create new rule
$fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $type
$fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
# Apply new rule
$NewAcl.SetAccessRule($fileSystemAccessRule)

# Apply ACL
Set-Acl -Path $authorizedKeyFile -AclObject $NewAcl

Restart-Service sshd
