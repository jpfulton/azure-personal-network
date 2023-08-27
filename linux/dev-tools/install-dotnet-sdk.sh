#!/usr/bin/env bash

DEBIAN_FRONTEND="noninteractive";

# Purge old packages
sudo apt-get remove 'dotnet.*' -y;
sudo apt-get remove 'aspnet.*' -y;

# Get Ubuntu version
declare repo_version=$(if command -v lsb_release &> /dev/null; then lsb_release -r -s; else grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"'; fi);

# Download Microsoft signing key and repository
wget -q https://packages.microsoft.com/config/ubuntu/$repo_version/packages-microsoft-prod.deb -O packages-microsoft-prod.deb;

# Install Microsoft signing key and repository
sudo dpkg -i packages-microsoft-prod.deb;

# Clean up
rm packages-microsoft-prod.deb;

# Establish preferences for MS feed
sudo sh -c "cat > /etc/apt/preferences.d/dotnet <<'EOF'
Package: dotnet*
Pin: origin packages.microsoft.com
Pin-Priority: 1001
EOF";

sudo sh -c "cat > /etc/apt/preferences.d/aspnet <<'EOF'
Package: aspnet*
Pin: origin packages.microsoft.com
Pin-Priority: 1001
EOF";

# Update packages
sudo apt-get update;

# Install the .NET 7 SDK
sudo apt-get install dotnet-sdk-7.0 -y;
