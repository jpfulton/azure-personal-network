#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(dirname "$0")/";
echo "Running ${0} from ${CURRENT_SCRIPT_DIR}";
echo;

# Import library functions
source ${CURRENT_SCRIPT_DIR}lib/azure-cli-functions.sh

print-usage () {
  echo "This script requires three parameters:";
  echo "  - resource group name";
  echo "  - server name";
  echo "  - size";
  echo;
}

parse-script-inputs () {
  if [ "$#" -ne 3 ]
    then
      print-usage;
      exit 1;
    else
      RESOURCE_GROUP="$1";
      SERVER_NAME="$2";
      VM_SIZE="$3";
  fi
}

resize-vm () {
  echo "Resizing virtual machine...";

  az vm resize \
    --resource-group $RESOURCE_GROUP \
    --name $SERVER_NAME \
    --size $VM_SIZE;

  echo "---";
  echo;
}

main () {
  parse-script-inputs $@;
  validate-az-cli-install;
  check-signed-in-user;

  resize-vm;

  echo "---";
  echo "Done.";
  echo;
}

time main $@;
