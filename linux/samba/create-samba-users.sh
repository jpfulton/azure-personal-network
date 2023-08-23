#!/usr/bin/env bash

DEPLOYMENT_OUTPUT_FILE="samba-users.txt";

APPLE_BACKUP_USER="applebackup";
APPLE_BACKUP_USER_PASS="$(openssl rand -base64 12)";
LINUX_BACKUP_USER="linuxbackup";
LINUX_BACKUP_USER_PASS="$(openssl rand -base64 12)";

sudo adduser --no-create-home --disabled-password --shell /sbin/nologin --gecos "Apple Backup User" $APPLE_BACKUP_USER;
sudo echo "${APPLE_BACKUP_USER}:$(openssl rand -base64 12)" | sudo chpasswd;
(echo "$APPLE_BACKUP_USER_PASS"; echo "$APPLE_BACKUP_USER_PASS") | sudo smbpasswd -s -a $APPLE_BACKUP_USER;

sudo adduser --no-create-home --disabled-password --shell /sbin/nologin --gecos "Linux Backup User" $LINUX_BACKUP_USER;
sudo echo "${LINUX_BACKUP_USER}:$(openssl rand -base64 12)" | sudo chpasswd;
(echo "$LINUX_BACKUP_USER_PASS"; echo "$LINUX_BACKUP_USER_PASS") |sudo smbpasswd -s -a $LINUX_BACKUP_USER;

touch $DEPLOYMENT_OUTPUT_FILE;
echo "Samba Share Users:" > $DEPLOYMENT_OUTPUT_FILE;
echo "" >> $DEPLOYMENT_OUTPUT_FILE;
echo "${APPLE_BACKUP_USER}:${APPLE_BACKUP_USER_PASS}" >> $DEPLOYMENT_OUTPUT_FILE;
echo "${LINUX_BACKUP_USER}:${LINUX_BACKUP_USER_PASS}" >> $DEPLOYMENT_OUTPUT_FILE;
