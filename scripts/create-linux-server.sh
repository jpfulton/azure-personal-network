#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(dirname "$0")/";
echo "Running ${0} from ${CURRENT_SCRIPT_DIR}";
echo "---";
echo;

# Import library functions
source ${CURRENT_SCRIPT_DIR}lib/azure-cli-functions.sh;
source ${CURRENT_SCRIPT_DIR}lib/sshpass-functions.sh;

# Set remote execution PS script
REMOTE_EXECUTION_PS_FILE="${CURRENT_SCRIPT_DIR}../powershell/admin/run-file-on-remote-server.ps1";

print-usage () {
  echo "Usage: ${0} [options] [resource-group] [server-name]";
  echo;
  echo "Options:";
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
  OPTIONS=$(getopt --options o --long openvpn --name "$SCRIPT_NAME" -- "$@");
  if [ $? -ne 0 ]
    then
      echo "Incorrect options.";
      print-usage;
      exit 1;
  fi

  OPENVPN=0;

  eval set -- "$OPTIONS";
  shift 6; # jump past the getopt options in the options string

  while true; do
    case "$1" in
      -o|--openvpn)
        OPENVPN=1; shift ;;
      --) 
        shift; ;;
      *) 
        break ;;
    esac
  done

  if [ "$OPENVPN" -eq 1 ]
    then
      echo "Enabling OpenVPN installation.";
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

  read -p "Enter a vm size [Standard_DS1_v2]: " VM_SIZE;
  VM_SIZE=${VM_SIZE:-Standard_DS1_v2};

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

  read -p "Enter the path to the admin public SSH key [~/.ssh/id_rsa.pub]: " ADMIN_PUBLIC_KEY_FILE;
  ADMIN_PUBLIC_KEY_FILE=${ADMIN_PUBLIC_KEY_FILE:-~/.ssh/id_rsa.pub};

  if [ ! -f $ADMIN_PUBLIC_KEY_FILE ]
    then
      echo "Cannot find admin public key file. Exiting...";
      exit 1;
  fi

  read -p "Enter the path to the admin private SSH key [~/.ssh/id_rsa]: " ADMIN_PRIVATE_KEY_FILE;
  ADMIN_PRIVATE_KEY_FILE=${ADMIN_PRIVATE_KEY_FILE:-~/.ssh/id_rsa};

  if [ ! -f $ADMIN_PRIVATE_KEY_FILE ]
    then
      echo "Cannot find admin private key file. Exiting...";
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
  echo "Using admin public key file: $ADMIN_PUBLIC_KEY_FILE";
  echo "Using admin private key file: $ADMIN_PRIVATE_KEY_FILE";
  echo;
  echo "Public key: $(cat $ADMIN_PUBLIC_KEY_FILE)";
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
  export ADMIN_PUBLIC_KEY="$(cat $ADMIN_PUBLIC_KEY_FILE)";

  local TEMPLATE_FILE="${CURRENT_SCRIPT_DIR}../bicep/linux-server.bicep";
  local PARAM_FILE="${CURRENT_SCRIPT_DIR}../bicep/linux-server.bicepparam";
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

login-to-admin-acct () {
  echo "Logging into to admin account and recording host key...";

  ssh -i $ADMIN_PRIVATE_KEY_FILE \
    -o StrictHostKeyChecking=accept-new \
    ${ADMIN_USERNAME}@${SERVER_FQDN} \
    sleep 1;

  echo "---";
  echo;
}

scp-file-to-admin-home () {
  if [ "$#" -ne 1 ]
    then
      echo "ERROR: scp-file-to-admin-home function requires one argument. Exiting...";
      echo "INFO:  Required argument one: Path to file to copy.";
      echo;

      exit 1;
  fi

  local FILE="$1";

  if [ ! -f $FILE ]
    then
      echo "Cannot find file: ${FILE} Exiting...";
      exit 1;
  fi

  echo "SCPing ${FILE} to remote admin home folder...";
  scp \
    -i $ADMIN_PRIVATE_KEY_FILE \
    $FILE \
    ${ADMIN_USERNAME}@${SERVER_FQDN}:~/;

  echo "---";
  echo;
}

run-script-from-admin-home () {
  if [ "$#" -ne 1 ]
    then
      echo "ERROR: exec-script-as-sudo-from-admin-home function requires one argument. Exiting...";
      echo "INFO:  Required argument one: Path to file to copy.";
      echo;

      exit 1;
  fi

  local SCRIPT="$1";

  echo "Executing remote script: ${SCRIPT}...";

  ssh -i $ADMIN_PRIVATE_KEY_FILE \
    ${ADMIN_USERNAME}@${SERVER_FQDN} \
    "./${SCRIPT}";

  echo "---";
  echo;
}

scp-notifier-config () {
  echo "Copying SMS Nofifier config...";

  local NOTIFIER_CONFIG="/etc/sms-notifier/notifier.json"
  local REMOTE_LOCATION="~/"

  if [ -f $NOTIFIER_CONFIG ]
    then
      scp -i $ADMIN_PRIVATE_KEY_FILE \
        $NOTIFIER_CONFIG \
        ${ADMIN_USERNAME}@${SERVER_FQDN}:${REMOTE_LOCATION};

      run-script-from-admin-home update-notifier-config.sh;
    else
      echo "WARN: Manual installation of notifier config will be required.";
  fi
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
  validate-az-cli-install;
  validate-sshpass-install;

  # parse script inputs and gather user inputs
  parse-script-inputs $@;
  get-user-inputs;

  # check for signed in Azure CLI user
  check-signed-in-user;

  # deploy bicep template
  deploy;

  # log into admin account and record host key
  login-to-admin-acct;

  # copy setup scripts to server
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux-scripts/core/update-base-packages.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux-scripts/core/setup-firewall.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux-scripts/core/setup-motd.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux-scripts/core/setup-node-and-yarn.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux-scripts/spot/setup-sms-notifier.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux-scripts/spot/setup-eviction-shutdown-system.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux-scripts/spot/update-notifier-config.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux-scripts/core/clean-up.sh;

  # execute remote setup scripts
  run-script-from-admin-home update-base-packages.sh;
  run-script-from-admin-home setup-firewall.sh;
  run-script-from-admin-home setup-motd.sh;
  run-script-from-admin-home setup-node-and-yarn.sh;
  
  if [ "$IS_SPOT" = "true" ]
    then
      run-script-from-admin-home setup-sms-notifier.sh;
      scp-notifier-config;
      run-script-from-admin-home setup-eviction-shutdown-system.sh;

      if [ "$SPOT_RESTART" = "true" ]
        then
          echo "Tagging VM for restart after eviction...";

          local VM_ID=$(az-get-vm-resource-id $RESOURCE_GROUP $SERVER_NAME);
          az-add-tag-to-resource $VM_ID "AttemptRestartAfterEviction=true";
      fi
  fi

  run-script-from-admin-home clean-up.sh;

  echo "---";
  echo "Done.";
  echo;
}

time main $@;
