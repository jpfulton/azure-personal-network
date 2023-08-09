#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(dirname "$0")/";
echo "Running ${0} from ${CURRENT_SCRIPT_DIR}";
echo;

# Import library functions
source ${CURRENT_SCRIPT_DIR}lib/azure-cli-functions.sh

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

delete-vm () {
  echo "Deleting virtual machine...";

  az vm delete --yes \
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

  echo "---";
  echo "Done.";
  echo;
}

time main $@;