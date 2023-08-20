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
REMOTE_EXECUTION_PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/run-file-on-remote-server.ps1";

print-usage () {
  echo "Usage: ${0} [options] [resource-group] [server-name]";
  echo;
  echo "Options:";
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
  OPTIONS=$(getopt --options nwud --long no-nla,no-wsl,no-windows-updates,no-dev-tools,personal-repos --name "$SCRIPT_NAME" -- "$@");
  if [ $? -ne 0 ]
    then
      echo "Incorrect options.";
      print-usage;
      exit 1;
  fi

  NO_NLA=0;
  NO_WSL=0;
  NO_WIN_UPDATES=0;
  NO_DEV_TOOLS=0;
  PERSONAL_REPOS=0;

  eval set -- "$OPTIONS";
  shift 6; # jump past the getopt options in the options string

  while true; do
    case "$1" in
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

  read -p "Create server as spot instance (true/false)[true]: " IS_SPOT;
  IS_SPOT=${IS_SPOT:-true};

  if [ ! "$IS_SPOT" = "true" ] && [ ! "$IS_SPOT" = "false" ]
    then
      echo "Spot instance prompt must be either true or false. Exiting...";
      exit 1;
  fi

  if [ "$IS_SPOT" = true ]
    then
      read -p "Tag for restart after eviction (true/false)[true]: " SPOT_RESTART;
      SPOT_RESTART=${SPOT_RESTART:-true};

      if [ ! "$SPOT_RESTART" = "true" ] && [ ! "$SPOT_RESTART" = "false" ]
        then
          echo "Spot instance restart prompt must be either true or false. Exiting...";
          exit 1;
      fi
  fi

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
  export IS_SPOT="$IS_SPOT";
  export ADMIN_USERNAME="$ADMIN_USERNAME";

  # export admin pass to evironment variable for use in script
  # using an environment variable keeps the password off the command line
  # which can be potentially seen in ps queries by other system users
  export ADMIN_PASSWORD="$SCRIPT_LOCAL_ADMIN_PASSWORD";

  local TEMPLATE_FILE="${CURRENT_SCRIPT_DIR}../bicep/win-server.bicep";
  local PARAM_FILE="${CURRENT_SCRIPT_DIR}../bicep/win-server.bicepparam";
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

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/azure/disable-nla.ps1";
  run-azure-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE;
}

run-ps-install-ssh () {
  echo "Installing SSH...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/azure/install-ssh.ps1";
  run-azure-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE;
}

run-ps-copy-local-public-key () {
  echo "Installing local public key to server...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/copy-ssh-public-key-to-server.ps1";
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

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/wsl/enable-virtual-machine-platform.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-wsl () {
  echo "Installing WSL...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/wsl/install-wsl.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-config-wsl () {
  echo "Configuring WSL with Ubuntu 22.04 LTS...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/wsl/config-wsl.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-update-wsl-distro () {
  echo "Updating base packages in WSL Ubuntu 22.04 LTS installation...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/wsl/update-wsl-distro.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-enable-systemd-wsl () {
  echo "Enabling systemd in WSL Ubuntu 22.04 LTS installation...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/wsl/enable-wsl-systemd.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-choco () {
  echo "Installing Chocolatey...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/general/install-choco.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-git () {
  echo "Installing Git...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/dev-tools/install-git.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-gpg4win () {
  echo "Installing GPG4Win...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/dev-tools/install-gpg4win.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-native-build-libs () {
  echo "Installing native build libraries...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/dev-tools/install-native-build-libs.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-nodejs () {
  echo "Installing NodeJS...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/general/install-nodejs.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-yarn () {
  echo "Installing Yarn...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/general/install-yarn.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

ps-install-sms-notifier () {
  echo "Installing SMS Notifier CLI...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/spot/install-sms-notifier.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

scp-notifier-config () {
  echo "Copying SMS Nofifier config...";

  local NOTIFIER_CONFIG="/etc/sms-notifier/notifier.json"
  local REMOTE_LOCATION="/C:/ProgramData/sms-notifier/notifier.json"

  if [ -f $NOTIFIER_CONFIG ]
    then
      scp $NOTIFIER_CONFIG ${ADMIN_USERNAME}@${SERVER_FQDN}:${REMOTE_LOCATION};
    else
      echo "WARN: Manual installation of notifier config will be required.";
  fi
}

run-ps-install-dotnet-7 () {
  echo "Installing .NET 7 runtime...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/general/install-dotnet-7.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-spot-eviction-service () {
  echo "Installing Spot Instance Eviction Service...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/spot/install-eviction-query-service.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-dotnet-7-sdk () {
  echo "Installing .NET 7 SDK...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/dev-tools/install-dotnet-7-sdk.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-vscode () {
  echo "Installing VS Code...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/dev-tools/install-vscode.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-install-chrome () {
  echo "Installing Google Chrome...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/dev-tools/install-chrome.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-checkout-personal-repos () {
  echo "Checking out personal repositories...";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/admin/dev-tools/checkout-jpfulton-repos.ps1";
  run-ps-as-admin $REMOTE_EXECUTION_PS_FILE $PS_FILE $ADMIN_USERNAME $SERVER_FQDN;
}

run-ps-config-and-run-windows-update () {
  echo "Configuring and then running Windows Updates...";
  echo "The server _may_ reboot after this step.";

  local PS_FILE="${CURRENT_SCRIPT_DIR}../windows/azure/configure-windows-update.ps1";
  run-azure-ps $RESOURCE_GROUP $SERVER_NAME $PS_FILE --no-wait;
}

restart-vm () {
  echo "Restarting VM to allow settings to take effect...";

  # az vm restart can hang, using the --no-wait flag causes the az cli to return
  # without waiting for the long running operaton, the following sleep command
  # gives time for the vm to restart, scripts followiing this step should use
  # a retry loop when connecting to vm in case it is still in boot mode
  az vm restart \
    --no-wait \
    -g $RESOURCE_GROUP \
    -n $SERVER_NAME;

  sleep 180; # set based on average restart time on a 2 CPU instance

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

  # deploy bicep template
  deploy;

  # install ssh backed by powershell
  run-ps-install-ssh;
  run-ps-copy-local-public-key;

  if [ "$NO_NLA" -eq 0 ]
    then
      run-ps-disable-nla; # mandatory restart will be caught in next step
  fi

  # install Chocolately package manager
  run-ps-install-choco;
  restart-vm;

  # install NodeJS and Yarn
  run-ps-install-nodejs;
  restart-vm;
  run-ps-install-yarn;

  # install .NET 7 runtime
  run-ps-install-dotnet-7;

  if [ "$IS_SPOT" = "true" ]
    then
      ps-install-sms-notifier;
      scp-notifier-config;
      run-ps-install-spot-eviction-service;

      if [ "$SPOT_RESTART" = "true" ]
        then
          echo "Tagging VM for restart after eviction...";

          local VM_ID=$(az-get-vm-resource-id $RESOURCE_GROUP $SERVER_NAME);
          az-add-tag-to-resource $VM_ID "AttemptRestartAfterEviction=true";
      fi
  fi

  if [ "$NO_WSL" -eq 0 ]
    then
      #run-ps-install-vmp;
      #restart-vm;
      run-ps-install-wsl;
      restart-vm;
      run-ps-config-wsl;
      #run-ps-update-wsl-distro;
      #run-ps-enable-systemd-wsl;
  fi

  if [ "$NO_DEV_TOOLS" -eq 0 ]
    then
      run-ps-install-dotnet-7-sdk;
      run-ps-install-git;
      run-ps-install-gpg4win;
      run-ps-install-native-build-libs;
      run-ps-install-vscode;
      run-ps-install-chrome;
      restart-vm;

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
