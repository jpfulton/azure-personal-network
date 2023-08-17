#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(dirname "$0")/";
echo "Running ${0} from ${CURRENT_SCRIPT_DIR}";
echo "---";
echo;

# Import library functions
source ${CURRENT_SCRIPT_DIR}lib/azure-cli-functions.sh;

print-usage () {
  echo "Usage: ${0} [resource-group-name]";
  echo;
  echo "Options:";
  echo "---";
  echo;
}

parse-script-inputs () {
  echo "Parsing script inputs...";
  echo "---";

  if [ "$#" -ne 1 ]
    then
      print-usage $@;
      exit 1;
  fi

  RESOURCE_GROUP_NAME="$1";
  if [ "$RESOURCE_GROUP_NAME" == "" ]
    then
      print-usage;
      exit 1;
  fi

  echo "---";
  echo;
}

main () {
  validate-az-cli-install;

  # parse script inputs
  parse-script-inputs $@;

  # check for signed in Azure CLI user
  check-signed-in-user;

  # delete resource group
  az-delete-resource-group $RESOURCE_GROUP_NAME;

  echo "---";
  echo "Done.";
  echo;
}

time main $@;
