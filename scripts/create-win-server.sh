#!/usr/bin/env bash

print-usage () {
  echo "This script requires two parameters:";
  echo "  - resource group name";
  echo "  - server name";
  echo;
}

parse-script-inputs () {
  if [ "$#" -ne 2 ]
    then
      print-usage;
      exit 1;
    else
      RESOURCE_GROUP="$1";
      SERVER_NAME="$2";
  fi
}

validate-az-cli-install () {
  which az > /dev/null;
  if [ "$?" -ne 0 ]
    then
      echo "Azure CLI not found. Please install the Azure CLI. Exiting...";
      exit 1;
  fi
}

check-signed-in-user () {
  echo "Checking for current Azure User:";
  az ad signed-in-user show;
  if [ $? -ne 0 ]
    then
      echo "Azure Login required... Run 'az login'.";
      exit 1;
  fi
  echo;
}

deploy () {
  echo "Launching deployment...";

  local TEMPLATE_FILE="../bicep/win-server-spot.bicep";
  az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file $TEMPLATE_FILE \
    --parameters serverName=$SERVER_NAME;

  echo "---";
  echo;
}

run-ps-disable-nla () {
  echo "Disabling NLA for RDP...";

  local PS_FILE="../powershell/disable-nla.ps1";
  az vm run-command invoke \
    --command-id RunPowerShellScript \
    --name $SERVER_NAME \
    -g $RESOURCE_GROUP \
    --scripts @${PS_FILE};

  if [ $? -ne 0 ]
    then
      echo "Deployment failed. Exiting.";
      exit 1;
  fi

  echo "---";
  echo;
}

run-ps-install-ssh () {
  echo "Installing SSH...";

  local PS_FILE="../powershell/install-ssh.ps1";
  az vm run-command invoke \
    --command-id RunPowerShellScript \
    --name $SERVER_NAME \
    -g $RESOURCE_GROUP \
    --scripts @${PS_FILE};

  echo "---";
  echo;
}

restart-vm () {
  echo "Restarting VM to allow settings to take effect...";

  az vm restart \
    -g $RESOURCE_GROUP \
    -n $SERVER_NAME;

  echo "---";
  echo;
}

main () {
  parse-script-inputs $@;
  validate-az-cli-install;
  check-signed-in-user;
  deploy;
  run-ps-install-ssh;
  run-ps-disable-nla;
  restart-vm;

  echo "---";
  echo "Done.";
  echo;
}

main $@;
