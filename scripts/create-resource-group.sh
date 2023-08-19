#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(dirname "$0")/";
echo "Running ${0} from ${CURRENT_SCRIPT_DIR}";
echo "---";
echo;

# Import library functions
source ${CURRENT_SCRIPT_DIR}lib/azure-cli-functions.sh;

print-usage () {
  echo "Usage: ${0} [resource-group-name] [location]";
  echo;
  echo "Options:";
  echo "---";
  echo;
}

parse-script-inputs () {
  echo "Parsing script inputs...";
  echo "---";

  if [ "$#" -ne 2 ]
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

  LOCATION="$2";
  if [ "$LOCATION" == "" ]
    then
      print-usage;
      exit 1;
  fi

  echo "---";
  echo;
}

add-current-user-to-vm-admin-role () {
  local MY_AD_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv);
  local SUBSCRIPTION_ID=$(az account show --query id -o tsv);
  local SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}";
  local ROLE="Virtual Machine Administrator Login";

  echo "Using user object id: $MY_AD_OBJECT_ID";
  echo "Using scope: $SCOPE";
  echo "Using role: $ROLE";
  echo;

  az role assignment create \
    --assignee $MY_AD_OBJECT_ID \
    --role "$ROLE" \
    --scope "$SCOPE";
}

main () {
  validate-az-cli-install;

  # parse script inputs
  parse-script-inputs $@;

  # check for signed in Azure CLI user
  check-signed-in-user;

  # create resource group
  az-create-resource-group $RESOURCE_GROUP_NAME $LOCATION;

  # assign current az cli user as Virtual Machine Administrator Login for resource group
  add-current-user-to-vm-admin-role;

  echo "---";
  echo "Done.";
  echo;
}

time main $@;
