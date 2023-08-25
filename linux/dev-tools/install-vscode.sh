#!/usr/bin/env bash

DEBIAN_FRONTEND="noninteractive";

# Install VSCode

# Get dependencies
sudo -E apt-get install software-properties-common apt-transport-https -y;
# Install the GPG key
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -;
# Add the VSCode package repo
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" -y;
# Install VS Code package
sudo apt-get install code -y;