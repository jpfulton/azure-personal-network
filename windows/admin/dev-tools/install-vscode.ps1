# Install VSCode with Powershell and WSL extensions for all system users

function Install-VSCode {
  param(
      [parameter()]
      [ValidateSet(,"64-bit","32-bit")]
      [string]$Architecture = "64-bit",

      [parameter()]
      [ValidateSet("stable","insider")]
      [string]$BuildEdition = "stable",

      [Parameter()]
      [ValidateNotNull()]
      [string[]]$AdditionalExtensions = @(),

      [switch]$LaunchWhenDone
  )

  if (($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) {
      switch ($Architecture) {
          "64-bit" {
              if ((Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture -eq "64-bit") {
                  $codePath = $env:ProgramFiles
                  $bitVersion = "win32-x64"
              }
              else {
                  $codePath = $env:ProgramFiles
                  $bitVersion = "win32"
                  $Architecture = "32-bit"
              }
              break;
          }
          "32-bit" {
              if ((Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture -eq "32-bit"){
                  $codePath = $env:ProgramFiles
                  $bitVersion = "win32"
              }
              else {
                  $codePath = ${env:ProgramFiles(x86)}
                  $bitVersion = "win32"
              }
              break;
          }
      }
      switch ($BuildEdition) {
          "Stable" {
              $codeCmdPath = "$codePath\Microsoft VS Code\bin\code.cmd"
              $appName = "Visual Studio Code ($($Architecture))"
              break;
          }
          "Insider" {
              $codeCmdPath = "$codePath\Microsoft VS Code Insiders\bin\code-insiders.cmd"
              $appName = "Visual Studio Code - Insiders Edition ($($Architecture))"
              break;
          }
      }
      try {
          $ProgressPreference = 'SilentlyContinue'

          if (!(Test-Path $codeCmdPath)) {
              Write-Host "`nDownloading latest $appName..." -ForegroundColor Yellow
              Remove-Item -Force "$env:TEMP\vscode-$($BuildEdition).exe" -ErrorAction SilentlyContinue
              
              Invoke-WebRequest -Uri "https://code.visualstudio.com/sha/download?build=$($BuildEdition)&os=$($bitVersion)" -OutFile "$env:TEMP\vscode-$($BuildEdition).exe"

              Write-Host "`nInstalling $appName..." -ForegroundColor Yellow
              Start-Process -Wait "$env:TEMP\vscode-$($BuildEdition).exe" -ArgumentList /silent, /mergetasks=!runcode
          }
          else {
              Write-Host "`n$appName is already installed." -ForegroundColor Yellow
          }

          $extensions = @("ms-vscode.PowerShell") + $AdditionalExtensions
          foreach ($extension in $extensions) {
              Write-Host "`nInstalling extension $extension..." -ForegroundColor Yellow
              & $codeCmdPath --install-extension $extension
          }

          if ($LaunchWhenDone) {
              Write-Host "`nInstallation complete, starting $appName...`n`n" -ForegroundColor Green
              & $codeCmdPath
          }
          else {
              Write-Host "`nInstallation complete!`n`n" -ForegroundColor Green
          }
      }
      finally {
          $ProgressPreference = 'Continue'
      }
  }
  else {
      Write-Error "This script is currently only supported on the Windows operating system."
  }
}

Install-VSCode