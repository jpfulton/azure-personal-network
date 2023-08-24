#!/usr/bin/env bash

BASE_REPO_URL="https://raw.githubusercontent.com/jpfulton/example-linux-configs/main";
SAMBA_CONFIG_DIR="/etc/samba";
SAMBA_CONFIG_TEMPLATE="/smb.conf.template";
SAMBA_CONFIG="/smb.conf";

sudo mv ${SAMBA_CONFIG_DIR}${SAMBA_CONFIG} "${SAMBA_CONFIG_DIR}${SAMBA_CONFIG}.backup";

sudo wget -q ${BASE_REPO_URL}${SAMBA_CONFIG_DIR}${SAMBA_CONFIG_TEMPLATE};
sudo mv ".${SAMBA_CONFIG_TEMPLATE}" ${SAMBA_CONFIG_DIR}${SAMBA_CONFIG};

sudo systemctl start smbd;
