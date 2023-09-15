#!/usr/bin/env bash

export DEBIAN_FRONTEND="noninteractive";
BASE_REPO_URL="https://raw.githubusercontent.com/jpfulton/example-linux-configs/main";

# Set up custom MOTD script
MOTD_PATH="/etc/update-motd.d/";
MOTD_FILE="01-custom";
if [ ! -f ${MOTD_PATH}${MOTD_FILE} ]
  then
    echo "Setting up custom MOTD script...";

    sudo -E apt-get install -y neofetch inxi;
    sudo wget -q ${BASE_REPO_URL}${MOTD_PATH}${MOTD_FILE} -O ${MOTD_FILE};
    sudo chmod a+x ./${MOTD_FILE};
    sudo mv ./${MOTD_FILE} ${MOTD_PATH}${MOTD_FILE};

    echo "---";
    echo;
fi