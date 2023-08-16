#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(dirname "$0")/";
echo "Running ${0} from ${CURRENT_SCRIPT_DIR}";
echo;

# Import library functions
source ${CURRENT_SCRIPT_DIR}lib/azure-cli-functions.sh

print-usage () {
  echo "Usage: ${0} [resource-group] [server-name]";
  echo;
}

parse-script-inputs () {
  if [ "$#" -ne 2 ]
    then
      print-usage $@;
      exit 1;
    else
      RESOURCE_GROUP="$1";
      SERVER_NAME="$2";
  fi
}

tag-vm () {
  echo "Tagging virtual machine...";

  local VM_ID="$(az vm list --resource-group $RESOURCE_GROUP --query "[?name=='${SERVER_NAME}'].id" -o tsv)";
  
  az-add-tag-to-resource $VM_ID AttemptRestartAfterEviction=true;

  echo "---";
  echo;
}

main () {
  parse-script-inputs $@;
  validate-az-cli-install;
  check-signed-in-user;

  tag-vm;

  echo "---";
  echo "Done.";
  echo;
}

time main $@;
