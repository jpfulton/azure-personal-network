#!/usr/bin/env bash

# Enter the backup mount point
cd /backup

# Create share root folders
sudo mkdir applebackups
sudo mkdir linuxbackups

# Set ownership for the share root folders
sudo chown smbuser:smbgroup applebackups
sudo chown smbuser:smbgroup linuxbackups