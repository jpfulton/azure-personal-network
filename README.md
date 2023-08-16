# azure-personal-network

![License](https://img.shields.io/badge/License-MIT-blue)

A collection of
[Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep)
templates,
[PowerShell](https://learn.microsoft.com/en-us/powershell/)
scripts and shell scripts for working with a personal network in Azure.

Control scripts are stored in the `scripts` directory.

## Prerequisites

This project has dependencies upon Powershell, the Azure CLI and the sshpass utility.

## Install Dependencies on macOS

Install [Homebrew](https://brew.sh):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Install the Azure CLI:

```bash
brew update && brew install azure-cli
```

Install PowerShell:

```bash
brew update && brew install --cask powershell
```

Install the sshpass utility:

```bash
cd deps
./install-sshpass.sh
```

## Create a ED25519 SSH Key

This project requires the use of
[ED25519](https://statistics.berkeley.edu/computing/ssh-keys)
SSH keys. If one has not yet been generated for your workstation,
create one using the following command:

```bash
ssh-keygen -t ed25519 -C "username@domain.com"
```
