#!/usr/bin/env bash

DEPLOYMENT_OUTPUT_FILE="dev-users.txt";

if [ "$#" -ne 1 ]
  then
    echo "ERROR: This script requires one argument. Exiting...";
    echo "INFO:  Required argument one: Admin user name.";
    echo;

    exit 1;
fi

ADMIN_USERNAME="$1";

DEV_USER="${ADMIN_USERNAME}-dev";
DEV_USER_PASS="$(openssl rand -base64 12)"; # generate random password

sudo adduser --disabled-password --gecos "Development User" $DEV_USER;
sudo echo "${DEV_USER}:${DEV_USER_PASS}" | sudo chpasswd;

# Create a deployment output file with dev users and password for secure transfer to
# the control workstation later
touch $DEPLOYMENT_OUTPUT_FILE;
echo "Developer Users:" > $DEPLOYMENT_OUTPUT_FILE;
echo "" >> $DEPLOYMENT_OUTPUT_FILE;
echo "${DEV_USER}:${DEV_USER_PASS}" >> $DEPLOYMENT_OUTPUT_FILE;
