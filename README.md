# azure-personal-network

A collection of
[Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep)
templates,
[PowerShell](https://learn.microsoft.com/en-us/powershell/)
scripts and shell scripts for working with a personal network in Azure.

Control scripts are stored in the `scripts` directory.

## Prerequisites

This project has dependencies upon Powershell and the Azure CLI.

## Install Dependencies on macOS

Install [Homebrew](https://brew.sh):

```/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"```

Install the Azure CLI:

```brew update && brew install azure-cli```

Install PowerShell:

```brew update && brew install --cask powershell```
