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

delete-vm () {
  echo "Deleting virtual machine...";

  az vm delete \
    --resource-group $RESOURCE_GROUP \
    --name $SERVER_NAME;

  echo "---";
  echo;
}

delete-nsg () {
  echo "Deleting virtual machine NSG...";

  local NSG_NAME="${SERVER_NAME}-nsg";
  az network nsg delete \
    --resource-group $RESOURCE_GROUP \
    --name $NSG_NAME;

  echo "---";
  echo;
}

main () {
  parse-script-inputs $@;
  validate-az-cli-install;
  check-signed-in-user;
  delete-vm;
  delete-nsg;
}

main $@;