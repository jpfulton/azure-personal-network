#!/usr/bin/env bash

DEBIAN_FRONTEND="noninteractive";
BASE_REPO_URL="https://raw.githubusercontent.com/jpfulton/example-linux-configs/main";

setup-nodejs () {
  # Install Node as needed
  which node >> /dev/null;
  if [ $? -eq 0 ]
    then
      local NODE_VERSION=$(node --version);
      if [ $NODE_VERSION == "v12.22.9" ]
        then
          echo "Default node package detected. Removing.";
          sudo -E apt-get remove nodejs;
          sudo -E apt-get autoremove;
        else
          echo "Detected alternate version of node: ${NODE_VERSION}";
          echo "Ensure that version is above v18.0.0 or manually use nvm.";
      fi
    else
      echo "Node not detected. Preparing installation of node v18.x.";

      sudo curl -sL  https://deb.nodesource.com/setup_18.x | sudo bash -;
      sudo -E apt-get install -y nodejs;
  fi

  echo "---";
  echo;
}

setup-yarn () {
  # Install Yarn as needed
  which yarn >> /dev/null;
  if [ $? -eq 1 ]
    then
      echo "Yarn not detected. Preparing to install.";

      sudo curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null;
      sudo echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list;
      sudo -E apt-get update;
      sudo -E apt-get install -y yarn;
    else
      local YARN_VERSION=$(yarn --version);
      echo "Found yarn version: ${YARN_VERSION}";
  fi

  echo "---";
  echo;
}

setup-nodejs;
setup-yarn;