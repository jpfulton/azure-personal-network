#!/usr/bin/env bash

export DEBIAN_FRONTEND="noninteractive";

wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb;
chmod a+w ./google-chrome-stable_current_amd64.deb;
sudo apt-get install ./google-chrome-stable_current_amd64.deb -y;
