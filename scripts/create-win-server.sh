#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(dirname "$0")/";
echo "Running ${0} from ${CURRENT_SCRIPT_DIR}";
echo "---";
echo;

# Import library functions
source ${CURRENT_SCRIPT_DIR}lib/azure-cli-functions.sh;
source ${CURRENT_SCRIPT_DIR}lib/dependency-functions.sh;
source ${CURRENT_SCRIPT_DIR}lib/powershell-exec-functions.sh;
source ${CURRENT_SCRIPT_DIR}lib/sshpass-functions.sh;

# Set remote execution PS script
REMOTE_EXECUTION_PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/run-file-on-remote-server.ps1";

print-usage () {
  echo "Usage: ${0} [options] [resource-group] [server-name]";
  echo;
  echo "Options:";
  echo "  -s,--no-ssh:            Disable SSH installation.";
  echo "  -n,--no-nla:            Disable NLA disable script.";
  echo "  -w,--no-wsl:            Disable WSL installation.";
  echo "  -u,--no-windows-update: Disable Windows Update configuration and run.";
  echo "  -d,--no-dev-tools:      Disable development tools installation.";
  echo "  --personal-repos:       Enable checkout of personal repositories.";
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
  PERSONAL_REPOS=0;

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
      --personal-repos)
        PERSONAL_REPOS=1; shift ;;
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
  if [ "$SERVER_NAME" == "" ]
    then
      print-usage;
      exit 1;
  fi

  echo "---";
  echo;
}

get-user-inputs () {
  read -p "Enter a private DNS zone name [private.jpatrickfulton.com]: " PRIVATE_DNS_ZONE;
  PRIVATE_DNS_ZONE=${PRIVATE_DNS_ZONE:-private.jpatrickfulton.com};

  read -p "Enter a vm size [Standard_D2s_v3]: " VM_SIZE;
  VM_SIZE=${VM_SIZE:-Standard_D2s_v3};

  read -p "Enter an admin account username [jpfulton]: " ADMIN_USERNAME;
  ADMIN_USERNAME=${ADMIN_USERNAME:-jpfulton};

  read -s -p "Enter an admin account password: " SCRIPT_LOCAL_ADMIN_PASSWORD;

  if [ "$SCRIPT_LOCAL_ADMIN_PASSWORD" = "" ]
  then
    echo;
    echo "Admin account password cannot be empty. Exiting...";
    exit 1;
  fi

  SERVER_FQDN="${SERVER_NAME}.${PRIVATE_DNS_ZONE}";

  echo;
  echo;
  echo "---";
  echo "Using resource group: $RESOURCE_GROUP";
  echo "Using server name: $SERVER_NAME";
  echo "Using full server private DNS name: $SERVER_FQDN";
  echo "Using admin account username: $ADMIN_USERNAME";
  echo;

  echo "---";
  echo;
}

deploy () {
  echo "Launching deployment...";

  export SERVER_NAME="$SERVER_NAME";
  export VM_SIZE="$VM_SIZE";
  export ADMIN_USERNAME="$ADMIN_USERNAME";

  # export admin pass to evironment variable for use in script
  # using an environment variable keeps the password off the command line
  # which can be potentially seen in ps queries by other system users
  export ADMIN_PASSWORD="$SCRIPT_LOCAL_ADMIN_PASSWORD";

  local TEMPLATE_FILE="${CURRENT_SCRIPT_DIR}../bicep/win-server-spot.bicep";
  local PARAM_FILE="${CURRENT_SCRIPT_DIR}../bicep/win-server-spot.bicepparam";
  az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file $TEMPLATE_FILE \
    --parameters $PARAM_FILE;

  export ADMIN_PASSWORD=""; # reset the evironment variable after use

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

  # export admin pass to evironment variable for use in script
  # using an environment variable keeps the password off the command line
  # which can be potentially seen in ps queries by other system users
  export ADMIN_PASSWORD="$SCRIPT_LOCAL_ADMIN_PASSWORD";
  run-local-ps $PS_FILE "$ARGS";
  export ADMIN_PASSWORD=""; #reset the environment variable after use
}

run-ps-install-vmp () {
  echo "Enabling Virtual Machine Platfrom OS Feature...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/azure/enable-virtual-machine-platform.ps1";
  run-azure-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE;
}

run-ps-install-wsl () {
  echo "Installing WSL...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/wsl/install-wsl.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-config-wsl () {
  echo "Configuring WSL with Ubuntu 22.04 LTS...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/wsl/config-wsl.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-update-wsl-distro () {
  echo "Updating base packages in WSL Ubuntu 22.04 LTS installation...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/wsl/update-wsl-distro.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-enable-systemd-wsl () {
  echo "Enabling systemd in WSL Ubuntu 22.04 LTS installation...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/wsl/enable-wsl-systemd.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-choco () {
  echo "Installing Chocolatey...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/dev-tools/install-choco.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-git () {
  echo "Installing Git...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/dev-tools/install-git.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-native-build-libs () {
  echo "Installing native build libraries...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/dev-tools/install-native-build-libs.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-nodejs () {
  echo "Installing NodeJS...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/dev-tools/install-nodejs.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-yarn () {
  echo "Installing Yarn...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/dev-tools/install-yarn.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-vscode () {
  echo "Installing VS Code...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/dev-tools/install-vscode.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-chrome () {
  echo "Installing Google Chrome...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/dev-tools/install-chrome.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-checkout-personal-repos () {
  echo "Checking out personal repositories...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/dev-tools/checkout-jpfulton-repos.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-config-and-run-windows-update () {
  echo "Configuring and then running Windows Updates...";
  echo "The server _may_ reboot after this step.";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/azure/configure-windows-update.ps1";
  run-azure-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE --no-wait;
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
  validate-dependencies;

  # parse script inputs and gather user inputs
  parse-script-inputs $@;
  get-user-inputs;

  # check for signed in Azure CLI user
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
      run-ps-enable-systemd-wsl;
  fi

  if [ "$NO_DEV_TOOLS" -eq 0 ]
    then
      run-ps-install-choco;
      restart-vm;
      run-ps-install-git;
      run-ps-install-native-build-libs;
      run-ps-install-nodejs;
      restart-vm;
      run-ps-install-yarn;
      run-ps-install-vscode;
      run-ps-install-chrome;

      if [ "$PERSONAL_REPOS" -eq 1 ]
        then
          run-ps-checkout-personal-repos;
      fi
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
