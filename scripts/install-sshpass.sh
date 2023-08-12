#!/usr/bin/env bash

echo "WARN: This script installs the sshpass utility. Use it with caution.";
echo "WARN: Ensure you read the man page's security considerations prior to use outside of these scripts."
echo "---";
echo;

VERSION="1.10"
TMP_DIR="tmp-sshpass-build";
TAR_FILE="sshpass-${VERSION}.tar.gz";
URL="https://onboardcloud.dl.sourceforge.net/project/sshpass/sshpass/${VERSION}/${TAR_FILE}";

CURRENT_DIR=$(pwd);

echo "Creating temporary build directory...";
echo "---";
echo;
cd ~/;
mkdir $TMP_DIR;
cd $TMP_DIR;

echo "Downloading sshpass source...";
echo "---";
echo;
curl -L -O "$URL";

echo "Expanding source archive...";
echo "---";
echo;
tar -zxvf $TAR_FILE;

cd sshpass*;

echo "Configuring build...";
echo "---";
echo;
./configure;

echo "Running make install via sudo. Prepare to enter your sudo password...";
echo "---";
echo;
sudo make install;

echo "Cleaning up build directory...";
echo "---";
echo;
cd ~/;
rm -rf $TMP_DIR;

cd $CURRENT_DIR;

echo;
echo "---";
echo "Done.";
echo;
