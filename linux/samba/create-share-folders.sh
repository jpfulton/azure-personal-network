#!/usr/bin/env bash

cd /backup

sudo mkdir applebackups
sudo mkdir linuxbackups
sudo chown smbuser:smbgroup applebackups
sudo chown smbuser:smbgroup linuxbackups