#!/usr/bin/env bash

BASE_REPO_URL="https://raw.githubusercontent.com/jpfulton/example-linux-configs/main";
FUSE_CONFIG="fuse.conf";
FUSE_CONFIG_PATH="/etc/${FUSE_CONFIG}";

REPOS_DIR="repos";
FUSE_XATTRS_REPO="https://github.com/fbarriga/fuse_xattrs.git";

DEBIAN_FRONTEND="noninteractive";
sudo -E apt-get update;
sudo -E agt-get cmake make fuse libfuse-dev;

sudo wget -q ${BASE_REPO_URL}${FUSE_CONFIG_PATH} -O ${FUSE_CONFIG};
sudo mv ${FUSE_CONFIG} ${FUSE_CONFIG_PATH};

if [ ! -d $REPOS_DIR ];
  then
    mkdir $REPOS_DIR;
fi
cd $REPOS_DIR;

git clone $FUSE_XATTRS_REPO;
cd fuse_xattrs;

mkdir build;
cd build;
cmake ..;
make;
sudo make install;