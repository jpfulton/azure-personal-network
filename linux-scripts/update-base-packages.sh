#!/usr/bin/env bash

DEBIAN_FRONTEND="noninteractive";
sudo -E apt-get update;
sudo -E apt-get full-upgrade -y;