#!/usr/bin/env bash

# Currently hard coded constants
ADMIN_USERNAME="jpfulton";
PRIVATE_DNS_ZONE="private.jpatrickfulton.com";

CURRENT_SCRIPT_DIR="$(dirname "$0")/";
echo "Running ${0} from ${CURRENT_SCRIPT_DIR}";
echo "---";
echo;

# Import library functions
source ${CURRENT_SCRIPT_DIR}lib/azure-cli-functions.sh;
source ${CURRENT_SCRIPT_DIR}lib/powershell-exec-functions.sh;

# Set remote execution PS script
REMOTE_EXECUTION_PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/run-file-on-remote-server.ps1";

print-usage () {
  echo "Usage: ${0} [options] [resource-group] [server-name]";
  echo;
  echo "Options are used to disable default behaviors. No options performs all operations.";
  echo "Options:";
  echo "  -s,--no-ssh:            Disable SSH installation.";
  echo "  -n,--no-nla:            Disable NLA disable script.";
  echo "  -w,--no-wsl:            Disable WSL installation.";
  echo "  -u,--no-windows-update: Disable Windows Update configuration and run.";
  echo "  -d,--no-dev-tools:      Disable development tools installation.";
  echo "---";
  echo;
}

parse-script-inputs () {
  echo "Parsing script inputs...";
  echo "---";

  if [ "$#" -lt 2 ]
    then
      print-usage $@;
      exit 1;
  fi

  SCRIPT_NAME=$(basename "$0");
  OPTIONS=$(getopt --options snwud --long no-ssh,no-nla,no-wsl,no-windows-updates,no-dev-tools --name "$SCRIPT_NAME" -- "$@");
  if [ $? -ne 0 ]
    then
      echo "Incorrect options.";
      print-usage;
      exit 1;
  fi

  NO_SSH=0;
  NO_NLA=0;
  NO_WSL=0;
  NO_WIN_UPDATES=0;
  NO_DEV_TOOLS=0;

  eval set -- "$OPTIONS";
  shift 6; # jump past the getopt options in the options string

  while true; do
    case "$1" in
      -s|--no-ssh)
        NO_SSH=1; shift ;;
      -n|--no-nla)
        NO_NLA=1; shift ;;
      -w|--no-wsl)
        NO_WSL=1; shift ;;
      -u|--no-windows-updates)
        NO_WIN_UPDATES=1; shift ;;
      -d|--no-dev-tools)
        NO_DEV_TOOLS=1; shift ;;
      --) 
        shift; ;;
      *) 
        break ;;
    esac
  done

  if [ "$NO_SSH" -eq 1 ]
    then
      echo "Disabling SSH installation.";
  fi
  if [ "$NO_NLA" -eq 1 ]
    then
      echo "Disabling NLA script.";
  fi
  if [ "$NO_WSL" -eq 1 ]
    then
      echo "Disabling WSL installation.";
  fi
  if [ "$NO_WIN_UPDATES" -eq 1 ]
    then
      echo "Disabling Windows Update configuration and run.";
  fi
  if [ "$NO_DEV_TOOLS" -eq 1 ]
    then
      echo "Disabling development tools installation.";
  fi

  RESOURCE_GROUP="$1";
  if [ "$RESOURCE_GROUP" == "" ]
    then
      print-usage;
      exit 1;
  fi

  SERVER_NAME="$2";
  SERVER_FQDN="${SERVER_NAME}.${PRIVATE_DNS_ZONE}";
  if [ "$SERVER_NAME" == "" ]
    then
      print-usage;
      exit 1;
  fi

  echo "Using resource group: $RESOURCE_GROUP";
  echo "Using server name: $SERVER_NAME";
  echo "Using full server private DNS: $SERVER_FQDN";
  echo;

  echo "---";
  echo;
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

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/azure/disable-nla.ps1";
  run-azure-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE;
}

run-ps-install-ssh () {
  echo "Installing SSH...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/azure/install-ssh.ps1";
  run-azure-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE;
}

run-ps-copy-local-public-key () {
  echo "Installing local public key to server...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/copy-ssh-public-key-to-server.ps1";
  local ARGS="-username ${ADMIN_USERNAME} -hostname ${SERVER_FQDN}";
  run-local-ps $PS_FILE "$ARGS";
}

run-ps-install-vmp () {
  echo "Enabling Virtual Machine Platfrom OS Feature...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/azure/enable-virtual-machine-platform.ps1";
  run-azure-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE;
}

run-ps-install-wsl () {
  echo "Installing WSL...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/install-wsl.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-config-wsl () {
  echo "Configuring WSL with Ubuntu 22.04 LTS...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/config-wsl.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-update-wsl-distro () {
  echo "Updating base packages in WSL Ubuntu 22.04 LTS installation...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/update-wsl-distro.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-config-and-run-windows-update () {
  echo "Configuring and then running Windows Updates...";
  echo "The server _may_ reboot after this step.";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/azure/configure-windows-update.ps1";
  run-azure-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE;
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

  validate-local-ps-install;

  validate-az-cli-install;
  check-signed-in-user;

  deploy;

  if [ "$NO_SSH" -eq 0 ]
    then
      run-ps-install-ssh;
      run-ps-copy-local-public-key;
  fi

  if [ "$NO_NLA" -eq 0 ]
    then
      run-ps-disable-nla;
      restart-vm;
  fi

  if [ "$NO_WSL" -eq 0 ]
    then
      run-ps-install-vmp;
      restart-vm;
      run-ps-install-wsl;
      restart-vm;
      run-ps-config-wsl;
      run-ps-update-wsl-distro;
  fi

  if [ "$NO_WIN_UPDATES" -eq 0 ]
    then
      run-ps-config-and-run-windows-update;
  fi

  echo "---";
  echo "Done.";
  echo;
}

time main $@;
