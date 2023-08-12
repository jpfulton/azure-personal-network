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

start-vm () {
  echo "Starting virtual machine...";

  az vm start \
    --resource-group $RESOURCE_GROUP \
    --name $SERVER_NAME;

  echo "---";
  echo;
}

main () {
  parse-script-inputs $@;
  validate-az-cli-install;
  check-signed-in-user;

  start-vm;

  echo "---";
  echo "Done.";
  echo;
}

time main $@;
