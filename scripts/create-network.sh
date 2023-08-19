#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(dirname "$0")/";
echo "Running ${0} from ${CURRENT_SCRIPT_DIR}";
echo "---";
echo;

# Import library functions
source ${CURRENT_SCRIPT_DIR}lib/azure-cli-functions.sh;

print-usage () {
  echo "Usage: ${0} [resource-group]";
  echo;
  echo "Options:";
  echo "---";
  echo;
}

parse-script-inputs () {
  echo "Parsing script inputs...";
  echo "---";

  if [ "$#" -lt 1 ]
    then
      print-usage $@;
      exit 1;
  fi

  RESOURCE_GROUP="$1";
  if [ "$RESOURCE_GROUP" == "" ]
    then
      print-usage;
      exit 1;
  fi

  echo "---";
  echo;
}

get-user-inputs () {
  read -p "Enter a private DNS zone name [testing.jpatrickfulton.com]: " PRIVATE_DNS_ZONE;
  PRIVATE_DNS_ZONE=${PRIVATE_DNS_ZONE:-"testing.jpatrickfulton.com"};

  read -p "Enter a virtual network name [personal-network-vnet]: " VNET_NAME;
  VNET_NAME=${VNET_NAME:-"personal-network-vnet"};

  read -p "Enter a virtual network address space [10.1.0.0/16]: " ADDRESS_SPACE;
  ADDRESS_SPACE=${ADDRESS_SPACE:-"10.1.0.0/16"};

  read -p "Enter a default subnet address space [10.1.0.0/24]: " SUBNET_ADDRESS_SPACE;
  SUBNET_ADDRESS_SPACE=${SUBNET_ADDRESS_SPACE:-"10.1.0.0/24"};

  echo;
  echo;
  echo "---";
  echo "Using resource group: $RESOURCE_GROUP";
  echo "Using private DNS zone: $PRIVATE_DNS_ZONE";
  echo "Using virtual network name: $VNET_NAME";
  echo "Using address space: $ADDRESS_SPACE";
  echo "Using subnet address space: $SUBNET_ADDRESS_SPACE";
  echo;

  echo "---";
  echo;
}

deploy () {
  echo "Launching deployment...";

  export VNET_NAME="$VNET_NAME";
  export PRIVATE_DNS_ZONE="$PRIVATE_DNS_ZONE";
  export ADDRESS_SPACE="$ADDRESS_SPACE";
  export SUBNET_ADDRESS_SPACE="$SUBNET_ADDRESS_SPACE";

  local TEMPLATE_FILE="${CURRENT_SCRIPT_DIR}../bicep/networking.bicep";
  local PARAM_FILE="${CURRENT_SCRIPT_DIR}../bicep/networking.bicepparam";
  az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file $TEMPLATE_FILE \
    --parameters $PARAM_FILE;

  if [ $? -ne 0 ]
    then
      echo "Deployment failed. Exiting.";
      exit 1;
  fi

  echo "---";
  echo;
}

main () {
  validate-az-cli-install;

  # parse script inputs and gather user inputs
  parse-script-inputs $@;
  get-user-inputs;

  # check for signed in Azure CLI user
  check-signed-in-user;

  # deploy bicep template
  deploy;

  echo "---";
  echo "Done.";
  echo;
}

time main $@;
