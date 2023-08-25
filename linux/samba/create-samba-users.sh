#!/usr/bin/env bash

DEPLOYMENT_OUTPUT_FILE="samba-users.txt";

APPLE_BACKUP_USER="applebackup";
APPLE_BACKUP_USER_PASS="$(openssl rand -base64 12)"; # generate random smb password
LINUX_BACKUP_USER="linuxbackup";
LINUX_BACKUP_USER_PASS="$(openssl rand -base64 12)"; # generate random smb password

# Create a local system user with a random pass and no login capabilities
sudo adduser --no-create-home --disabled-password --shell /sbin/nologin --gecos "Apple Backup User" $APPLE_BACKUP_USER;
sudo echo "${APPLE_BACKUP_USER}:$(openssl rand -base64 12)" | sudo chpasswd;

# Set the apple back up user smb password
(echo "$APPLE_BACKUP_USER_PASS"; echo "$APPLE_BACKUP_USER_PASS") | sudo smbpasswd -s -a $APPLE_BACKUP_USER;

# Create a local system user with a random pass and no login capabilities
sudo adduser --no-create-home --disabled-password --shell /sbin/nologin --gecos "Linux Backup User" $LINUX_BACKUP_USER;
sudo echo "${LINUX_BACKUP_USER}:$(openssl rand -base64 12)" | sudo chpasswd;

# Set the linux back up user smb password
(echo "$LINUX_BACKUP_USER_PASS"; echo "$LINUX_BACKUP_USER_PASS") | sudo smbpasswd -s -a $LINUX_BACKUP_USER;

# Create a deployment output file with smb users and password for secure transfer to
# the control workstation later
touch $DEPLOYMENT_OUTPUT_FILE;
echo "Samba Share Users:" > $DEPLOYMENT_OUTPUT_FILE;
echo "" >> $DEPLOYMENT_OUTPUT_FILE;
echo "${APPLE_BACKUP_USER}:${APPLE_BACKUP_USER_PASS}" >> $DEPLOYMENT_OUTPUT_FILE;
echo "${LINUX_BACKUP_USER}:${LINUX_BACKUP_USER_PASS}" >> $DEPLOYMENT_OUTPUT_FILE;
