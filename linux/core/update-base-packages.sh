#!/usr/bin/env bash

export DEBIAN_FRONTEND="noninteractive";
sudo -E apt-get update;
sudo -E apt-get full-upgrade -y;