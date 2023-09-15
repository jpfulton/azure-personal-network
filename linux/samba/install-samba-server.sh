#!/usr/bin/env bash

# Install the samba package and dependencies
export DEBIAN_FRONTEND="noninteractive";
sudo -E apt-get update;
sudo -E apt-get install -y samba;

# Update the firewall to allow access to samba
sudo ufw allow samba;
sudo ufw status numbered;

# Create dedicated service user and group
sudo addgroup smbgroup;
sudo adduser --system --no-create-home --ingroup smbgroup smbuser;