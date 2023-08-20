#!/usr/bin/env bash

# Install or upgrade sms-notify-cli utility
which sms-notify-cli >> /dev/null;
if [ $? -eq 1 ]
  then
    echo "sms-notify-cli utility not detected. Preparing to install.";
    sudo yarn global add @jpfulton/net-sms-notifier-cli;
  else
    echo "Found sms-notify-cli utility. Attempting update.";
    sudo yarn global upgrade @jpfulton/net-sms-notifier-cli@latest;
fi
echo "---";
echo;

# Initialize sms-notify-cli configuration
NOTIFIER_CONFIG="/etc/sms-notifier/notifier.json";
if [ -f $NOTIFIER_CONFIG ]
  then
    echo "Found notifier configuration. Validating with current version.";

    sudo sms-notify-cli validate;
    if [ $? -eq 0 ]
      then
        echo "Configuration file validation passes on current version.";
      else
        echo "Invalid configuration file. Manually correct.";
    fi
  else
    echo "No notifier configuration found. Initializing...";
    echo "Manual configuration to the ${NOTIFIER_CONFIG} file will be required.";
    sudo sms-notify-cli init;
fi

echo "---";
echo;
