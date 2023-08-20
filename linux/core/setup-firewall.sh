#!/usr/bin/env bash

BASE_REPO_URL="https://raw.githubusercontent.com/jpfulton/example-linux-configs/main";

# Set up local firewall basics
DEFAULTS_PATH="/etc/default/";
UFW_DEFAULTS_FILE="ufw";
if [ $(sudo ufw status | grep -c inactive) -ge 1 ]
  then
    echo "Local firewall is inactive. Configuring and enabling with SSH rule...";

    sudo wget -q ${BASE_REPO_URL}${DEFAULTS_PATH}${UFW_DEFAULTS_FILE} -O ${UFW_DEFAULTS_FILE};
    sudo mv ${UFW_DEFAULTS_FILE} ${DEFAULTS_PATH};

    sudo ufw allow ssh;
    sudo ufw show added;
    sudo ufw --force enable;
    sudo ufw status numbered;
  
  else
    echo "Local fireall is active. No configuration or rules applied.";
fi
echo "---";
echo;