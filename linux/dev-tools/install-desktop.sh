#!/usr/bin/env bash

BASE_REPO_URL="https://raw.githubusercontent.com/jpfulton/example-linux-configs/main";
XRDP_CONFIG_DIR="/etc/xrdp/";
XRDP_WM_STARTUP_SCRIPT="startwm.sh";

export DEBIAN_FRONTEND="noninteractive";
sudo -E apt-get update;

# Install a minimal version of Gnome Desktop
# This step essentially upgrades from Ubuntu Server version to a minimal Ubuntu Desktop version
# X11 is a dependency
sudo -E apt-get install ubuntu-desktop-minimal -y;

# Install xRDP server
sudo -E apt-get install xrdp -y;

# Update xRDP start up script to provide traditional Gnome experience
sudo wget -q ${BASE_REPO_URL}${XRDP_CONFIG_DIR}${XRDP_WM_STARTUP_SCRIPT};
sudo chmod a+x ./${XRDP_WM_STARTUP_SCRIPT};
sudo mv ./${XRDP_WM_STARTUP_SCRIPT} ${XRDP_CONFIG_DIR}${XRDP_WM_STARTUP_SCRIPT};

# Open firewall to RDP port
sudo ufw allow 3389/tcp;
sudo ufw status numbered;
