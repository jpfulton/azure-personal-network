#!/usr/bin/env bash

sudo chown root:root ~/notifier.json
sudo chmod 0640 ~/notifier.json
sudo mv ~/notifier.json /etc/sms-notifier/notifier.json

echo "---";
echo;
