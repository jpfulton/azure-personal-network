#!/usr/bin/env bash

BASE_REPO_URL="https://raw.githubusercontent.com/jpfulton/example-linux-configs/main";
SAMBA_CONFIG_DIR="/etc/samba";
SAMBA_CONFIG_TEMPLATE="/smb.conf.template";
SAMBA_CONFIG="/smb.conf";

# Move the distro default config to a backup file
sudo mv ${SAMBA_CONFIG_DIR}${SAMBA_CONFIG} "${SAMBA_CONFIG_DIR}${SAMBA_CONFIG}.backup";

# Pull the remote smb.conf template from the remote repo and move it into place as main config
sudo wget -q ${BASE_REPO_URL}${SAMBA_CONFIG_DIR}${SAMBA_CONFIG_TEMPLATE};
sudo mv ".${SAMBA_CONFIG_TEMPLATE}" ${SAMBA_CONFIG_DIR}${SAMBA_CONFIG};

# Start the Samba service
sudo systemctl start smbd;
