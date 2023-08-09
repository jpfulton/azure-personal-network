#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(dirname "$0")/";
echo "Running ${0} from ${CURRENT_SCRIPT_DIR}";
echo;

# Import library functions
source ${CURRENT_SCRIPT_DIR}lib/azure-cli-functions.sh;
source ${CURRENT_SCRIPT_DIR}lib/powershell-exec-functions.sh;

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

deploy () {
  echo "Launching deployment...";

  local TEMPLATE_FILE="../bicep/win-server-spot.bicep";
  az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file $TEMPLATE_FILE \
    --parameters serverName=$SERVER_NAME;

  if [ $? -ne 0 ]
    then
      echo "Deployment failed. Exiting.";
      exit 1;
  fi

  echo "---";
  echo;
}

run-ps-disable-nla () {
  echo "Disabling NLA for RDP...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/disable-nla.ps1";
  run-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE;
}

run-ps-install-ssh () {
  echo "Installing SSH...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/install-ssh.ps1";
  run-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE;
}

run-ps-install-vmp () {
  echo "Enabling Virtual Machine Platfrom OS Feature...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/enable-virtual-machine-platform.ps1";
  run-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE;
}

run-ps-install-wsl () {
  echo "Installing WSL...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/install-wsl.ps1";
  run-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE;
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
  run-ps-install-vmp;
  restart-vm;

  run-ps-install-wsl;
  restart-vm;

  echo "---";
  echo "Done.";
  echo;
}

time main $@;
