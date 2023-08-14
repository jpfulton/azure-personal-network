#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(dirname "$0")/";
echo "Running ${0} from ${CURRENT_SCRIPT_DIR}";
echo;

# Import library functions
source ${CURRENT_SCRIPT_DIR}lib/azure-cli-functions.sh

print-usage () {
  echo "Usage: ${0} [resource-group]";
  echo;
}

parse-script-inputs () {
  if [ "$#" -ne 1 ]
    then
      print-usage $@;
      exit 1;
    else
      RESOURCE_GROUP="$1";
  fi
}

list-vms () {
  echo "Listing virtual machines in resource group...";
  echo;

  az vm list \
    -d \
    --resource-group $RESOURCE_GROUP \
    --query "[].{Name: name, Size: hardwareProfile.vmSize, State: powerState, Priority: priority, EvictionRestart: tags.AttemptRestartAfterEviction}" \
    --output table;

  echo "---";
  echo;
}

main () {
  parse-script-inputs $@;
  validate-az-cli-install;
  check-signed-in-user;

  list-vms;

  echo "---";
  echo "Done.";
  echo;
}

time main $@;
