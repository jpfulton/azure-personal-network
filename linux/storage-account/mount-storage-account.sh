#!/usr/bin/env bash

if [ "$#" -ne 2 ]
  then
    echo "ERROR: This script requires two arguments. Exiting...";
    echo "INFO:  Required argument one: Storage account name.";
    echo "INFO:  Required argument two: Storage account password.";
    echo;

    exit 1;
fi

STORAGE_ACCOUNT_NAME="$1";
STORAGE_ACCOUNT_PASSWORD="$2";

SHARE_NAME="backupshare";

MOUNT_POINT="/backup";
RAW_MOUNT_POINT="/backup-raw";

sudo mkdir $MOUNT_POINT;
sudo mkdir $RAW_MOUNT_POINT;

if [ ! -d "/etc/smbcredentials" ]; 
  then
    sudo mkdir /etc/smbcredentials;
fi

if [ ! -f "/etc/smbcredentials/${STORAGE_ACCOUNT_NAME}.cred" ]; 
  then
    echo "username=${STORAGE_ACCOUNT_NAME}" | sudo tee -a /etc/smbcredentials/${STORAGE_ACCOUNT_NAME}.cred > /dev/null;
    echo "password=${STORAGE_ACCOUNT_PASSWORD}" | sudo tee -a /etc/smbcredentials/${STORAGE_ACCOUNT_NAME}.cred > /dev/null;
fi

sudo chmod 600 /etc/smbcredentials/${STORAGE_ACCOUNT_NAME}.cred;

echo "//${STORAGE_ACCOUNT_NAME}.file.core.windows.net/${SHARE_NAME} ${RAW_MOUNT_POINT} cifs nofail,credentials=/etc/smbcredentials/${STORAGE_ACCOUNT_NAME}.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30" | sudo tee -a /etc/fstab > /dev/null;
sudo mount -t cifs //${STORAGE_ACCOUNT_NAME}.file.core.windows.net/${SHARE_NAME} ${RAW_MOUNT_POINT} -o credentials=/etc/smbcredentials/${STORAGE_ACCOUNT_NAME}.cred,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30;

sudo fuse_xattrs -o allow_other $RAW_MOUNT_POINT $MOUNT_POINT;
echo "fuse_xattrs#${RAW_MOUNT_POINT} ${MOUNT_POINT} fuse allow_other" | sudo tee -a /etc/fstab > /dev/null;
