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

## Install Rosetta if using Apple Silicon

Several dependencies required by this project are only built with Intel x86
instruction sets. As a result, if you are using a workstation based on Apple Silicon
processors, [Rosetta 2](<https://en.wikipedia.org/wiki/Rosetta_(software)>) needs to
be installed. Use the following command to install the Rosetta binary translator
to your workstation.

```bash
softwareupdate --install-rosetta
```

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
cd dependencies
./install-sshpass.sh
```

## Install Azure Subscription Features

The virtual machines created in this project utilize the Azure Encryption at Host
subscription feature to provide encryption between the virtual machine and managed
disk storage. This feature may not be registered for your subscription. Use the
following command to register the feature using the Azure CLI.

```bash
az feature register --namespace Microsoft.Compute --name EncryptionAtHost
```

It will take several minutes for the feature to be registered. Run the following
command to check registration status. Once the `state` property in the output
shows `Registered`, the feature will be ready to use and deployments of
virtual machines using it will succeed.

```bash
az feature show --namespace Microsoft.Compute --name EncryptionAtHost
```

## Create SSH Keys

Two varieties of local SSH keys will be required in this project:
an RSA key pair and a ED25519 key pair. The RSA key is required for the Linux
virtual machine workflows and the ED22519 key is required for the Windows Server
virtual machine workflows. The sections below provide the commands necessary
to create these keys if your workstation does not already have them in place.

### Create a RSA SSH Key

This project requires the use of a RSA SSH key. If one has not yet
been generated for your workstation, create one using the following
command.

```bash
ssh-keygen -b 4096 -t rsa
```

### Create a ED25519 SSH Key

This project requires the use of
[ED25519](https://statistics.berkeley.edu/computing/ssh-keys)
SSH keys. If one has not yet been generated for your workstation,
create one using the following command:

```bash
ssh-keygen -t ed25519 -C "username@domain.com"
```

## Install a Native OpenVPN Client

Install [Tunnelblick](https://tunnelblick.net/downloads.html) for macOS.
