#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(dirname "$0")/";
echo "Running ${0} from ${CURRENT_SCRIPT_DIR}";
echo "---";
echo;

# Import library functions
source ${CURRENT_SCRIPT_DIR}lib/azure-cli-functions.sh;

print-usage () {
  echo "Usage: ${0} [options] [resource-group] [server-name]";
  echo;
  echo "Options:";
  echo "  -o,--openvpn:                 Enable OpenVPN Server installation.";
  echo "  -b,--samba:                   Enable Samba Server installation with data disk.";
  echo "  -a,--samba-with-storage-acct: Enable Samba Server with storage account.";
  echo "  -s,--allow-ssh:               Enable installation over SSH on public IP.";
  echo "  -d,--dev-tools:               Enable desktop env and developer tools.";
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
  OPTIONS=$(getopt --options dobsa --long dev-tools,allow-ssh,samba,samba-with-storage-acct,openvpn --name "$SCRIPT_NAME" -- "$@");
  if [ $? -ne 0 ]
    then
      echo "Incorrect options.";
      print-usage;
      exit 1;
  fi

  ALLOW_SSH_RULE=0;
  OPENVPN=0;
  SAMBA=0;
  SAMBA_WITH_STORAGE=0;
  DEV_TOOLS=0;

  eval set -- "$OPTIONS";
  shift 6; # jump past the getopt options in the options string

  while true; do
    case "$1" in
      -o|--openvpn)
        OPENVPN=1; shift ;;
      -d|--dev-tools)
        DEV_TOOLS=1; shift ;;
      -b|--samba)
        SAMBA=1; shift ;;
      -a|--samba-with-storage-acct)
        SAMBA_WITH_STORAGE=1; shift ;;
      -s|--allow-ssh)
        ALLOW_SSH_RULE=1; shift ;;
      --) 
        shift; ;;
      *) 
        break ;;
    esac
  done

  if [ "$ALLOW_SSH_RULE" -eq 1 ]
    then
      echo "Enabling inbound SSH NSG rule and installation over public IP.";
  fi

  if [ "$OPENVPN" -eq 1 ]
    then
      echo "Enabling OpenVPN installation.";
  fi

  if [ "$SAMBA" -eq 1 ]
    then
      echo "Enabling Samba with data disk installation.";
  fi

  if [ "$SAMBA_WITH_STORAGE" -eq 1 ]
    then
      echo "Enabling Samba with storage account installation.";
      STORAGE_ACCOUNT_NAME="backupstorage$(openssl rand -hex 2)"; # generate random acct name
  fi

  if [ "$DEV_TOOLS" -eq 1 ]
    then
      echo "Enabling development tools installation.";
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
  if [ "$ALLOW_SSH_RULE" -eq 0 ]
    then
      # we only need this prompt if public SSH access is not enabled during install
      read -p "Enter a private DNS zone name [private.jpatrickfulton.com]: " PRIVATE_DNS_ZONE;
      PRIVATE_DNS_ZONE=${PRIVATE_DNS_ZONE:-private.jpatrickfulton.com};

      SERVER_FQDN="${SERVER_NAME}.${PRIVATE_DNS_ZONE}";
    else
      # this variable will be reset after the deployment
      SERVER_FQDN="Public IP will be used after deployment.";
  fi

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

  if [ "$OPENVPN" -eq 1 ]
    then
      read -p "Enter the virtual network address space [10.1.0.0]: " VNET_ADDRESS_SPACE;
      VNET_ADDRESS_SPACE=${VNET_ADDRESS_SPACE:-"10.1.0.0"};

      read -p "Enter a subnet for VPN clients [10.1.10.0]: " VPN_SUBNET;
      VPN_SUBNET=${VPN_SUBNET:-"10.1.10.0"};
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

  if [ "$ALLOW_SSH_RULE" -eq 1 ]
    then
      export ALLOW_SSH="true";
  fi

  if [ "$OPENVPN" -eq 1 ]
    then
      export ALLOW_OPENVPN="true";
  fi

  if [ "$SAMBA" -eq 1 ]
    then
      export ADD_DATA_DISK="true";
  fi

  if [ "$SAMBA_WITH_STORAGE" -eq 1 ]
    then
      export ADD_DATA_DISK="false";
      export ADD_STORAGE_ACCOUNT="true";
      export STORAGE_ACCOUNT_NAME="$STORAGE_ACCOUNT_NAME";
  fi

  local TEMPLATE_FILE="${CURRENT_SCRIPT_DIR}../bicep/linux-server.bicep";
  local PARAM_FILE="${CURRENT_SCRIPT_DIR}../bicep/linux-server.bicepparam";

  DEPLOYMENT_NAME=$(uuidgen);

  az deployment group create \
    --name $DEPLOYMENT_NAME \
    --resource-group $RESOURCE_GROUP \
    --template-file $TEMPLATE_FILE \
    --parameters $PARAM_FILE;

  if [ $? -ne 0 ]
    then
      echo "Deployment failed. Exiting.";
      exit 1;
  fi

  PUBLIC_IP=$(az deployment group show \
    -g $RESOURCE_GROUP \
    -n $DEPLOYMENT_NAME \
    --query properties.outputs.publicIp.value -o tsv);

  echo "Public IP is: $PUBLIC_IP";
  echo;

  if [ "$ALLOW_SSH_RULE" -eq 1 ]
    then
      echo "Allow public SSH rule was configured. Using public IP for next steps...";

      # Replace SERVER_FQDN with public IP for future steps
      SERVER_FQDN="$PUBLIC_IP";
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
      echo "ERROR: run-script-from-admin-home function requires one argument. Exiting...";
      echo "INFO:  Required argument one: Script to execute.";
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

  echo "---";
  echo;
}

create-local-deployment-outputs-dir () {
  DEPLOYMENT_OUTPUTS_DIR=~/deployment-outputs-${DEPLOYMENT_NAME};

  if [ ! -d $DEPLOYMENT_OUTPUTS_DIR ];
    then
      mkdir $DEPLOYMENT_OUTPUTS_DIR;
  fi
}

scp-to-deployment-outputs-dir () {
  if [ "$#" -ne 1 ]
    then
      echo "ERROR: scp-to-deployment-outputs-dir function requires one argument. Exiting...";
      echo "INFO:  Required argument one: File to scp to outputs directory.";
      echo;

      exit 1;
  fi

  local REMOTE_FILE="$1";

  scp -i $ADMIN_PRIVATE_KEY_FILE \
        ${ADMIN_USERNAME}@${SERVER_FQDN}:${REMOTE_FILE} \
        ${DEPLOYMENT_OUTPUTS_DIR}/;
}

az-remove-allow-ssh-nsg-rule () {
  echo "Removing NSG Allow SSH rule...";

  local NSG_NAME="${SERVER_NAME}-nsg";
  local RULE_NAME="AllowSsh";

  az network nsg rule delete \
    -g $RESOURCE_GROUP \
    --nsg-name $NSG_NAME \
    -n $RULE_NAME;

  echo "---";
  echo;
}

perform-core-setup () {
  # copy setup scripts to server
  echo "Copying base platform setup scripts...";
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/core/update-base-packages.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/core/setup-firewall.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/core/setup-motd.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/core/setup-node-and-yarn.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/spot/setup-sms-notifier.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/spot/setup-eviction-shutdown-system.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/spot/update-notifier-config.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/core/clean-up.sh;
  scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/core/restart.sh;

  # execute remote setup scripts
  echo "Executing base platform setup scripts...";
  run-script-from-admin-home update-base-packages.sh;
  run-script-from-admin-home setup-firewall.sh;
  run-script-from-admin-home setup-motd.sh;
  run-script-from-admin-home setup-node-and-yarn.sh;
  run-script-from-admin-home setup-sms-notifier.sh;
  scp-notifier-config;
}

perform-spot-setup () {
  if [ "$IS_SPOT" = "true" ]
    then
      echo "Executing spot instance setup scripts...";
      run-script-from-admin-home setup-eviction-shutdown-system.sh;

      if [ "$SPOT_RESTART" = "true" ]
        then
          echo "Tagging VM for restart after eviction...";

          local VM_ID=$(az-get-vm-resource-id $RESOURCE_GROUP $SERVER_NAME);
          az-add-tag-to-resource $VM_ID "AttemptRestartAfterEviction=true";
      fi
  fi
}

perform-openvpn-setup () {
  if [ "$OPENVPN" -eq 1 ]
    then
      echo "Copying OpenVPN setup scripts to server...";
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/openvpn/install-openvpn-and-deps.sh;
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/openvpn/create-server-certificates.sh;
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/openvpn/configure-openvpn-server.sh;
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/openvpn/create-client-config.sh;

      echo "Executing OpenVPN setup scripts...";
      run-script-from-admin-home install-openvpn-and-deps.sh;
      run-script-from-admin-home create-server-certificates.sh;
      run-script-from-admin-home "configure-openvpn-server.sh ${VNET_ADDRESS_SPACE} ${VPN_SUBNET} ${PUBLIC_IP}";
      run-script-from-admin-home "create-client-config.sh personal-network-client ${PUBLIC_IP}";

      echo "Gathering outputs to deployment output directory...";
      scp-to-deployment-outputs-dir "~/personal-network-client.ovpn";
  fi
}

perform-storage-account-mount () {
  run-script-from-admin-home install-fuse.sh;

  local STORAGE_ACCOUNT_PASSWORD=$(az storage account keys list \
    --resource-group $RESOURCE_GROUP \
    --account-name $STORAGE_ACCOUNT_NAME \
    --query "[0].value" --output tsv | tr -d '"');

  run-script-from-admin-home "mount-storage-account.sh $STORAGE_ACCOUNT_NAME $STORAGE_ACCOUNT_PASSWORD";
}

perform-samba-setup () {
  if [ "$SAMBA" -eq 1 ] || [ "$SAMBA_WITH_STORAGE" -eq 1 ]
    then
      echo "Copying Samba setup scripts to server...";

      if [ "$SAMBA" -eq 1 ]
        then
          scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/data-disk/format-and-mount-data-disk.sh;
        else
          scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/storage-account/install-fuse.sh;
          scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/storage-account/mount-storage-account.sh;
      fi

      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/samba/install-samba-server.sh;
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/samba/create-share-folders.sh;
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/samba/create-samba-users.sh;
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/samba/configure-and-start-samba.sh;

      echo "Executing Samba setup scripts...";

      if [ "$SAMBA" -eq 1 ]
        then
          run-script-from-admin-home format-and-mount-data-disk.sh;
        else
          perform-storage-account-mount;
      fi

      run-script-from-admin-home install-samba-server.sh;
      run-script-from-admin-home create-share-folders.sh;
      run-script-from-admin-home create-samba-users.sh;
      run-script-from-admin-home configure-and-start-samba.sh;

      echo "Gathering outputs to deployment output directory...";
      scp-to-deployment-outputs-dir "~/samba-users.txt";
  fi
}

perform-dev-tools-setup () {
  if [ "$DEV_TOOLS" -eq 1 ]
    then
      echo "Copying development tools setup scripts to server...";
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/dev-tools/install-dotnet-sdk.sh;
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/dev-tools/install-desktop.sh;
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/dev-tools/create-dev-user.sh;
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/dev-tools/enable-node-corepack.sh;
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/dev-tools/install-vscode.sh;
      scp-file-to-admin-home ${CURRENT_SCRIPT_DIR}../linux/dev-tools/install-chrome.sh;

      echo "Executing development tools setup scripts...";
      run-script-from-admin-home install-dotnet-sdk.sh;
      run-script-from-admin-home install-desktop.sh;
      run-script-from-admin-home "create-dev-user.sh ${ADMIN_USERNAME}";
      run-script-from-admin-home enable-node-corepack.sh;
      run-script-from-admin-home install-vscode.sh;
      run-script-from-admin-home install-chrome.sh;

      echo "Gathering outputs to deployment output directory...";
      scp-to-deployment-outputs-dir "~/dev-users.txt";
  fi
}

close-ssh-nsg-rule-if-needed () {
  if [ "$OPENVPN" -eq 1 ] && [ "$ALLOW_SSH_RULE" -eq 1 ];
    then
      echo "OpenVPN was sucessfully installed over the open SSH port.";
      echo "Closing SSH port in the server NSG. Future access should be performed over the VPN tunnel.";
      
      az-remove-allow-ssh-nsg-rule;
  fi
}

remove-empty-deployment-outputs-dir () {
  if [ "$(ls -A $DEPLOYMENT_OUTPUTS_DIR)" ]
    then
      echo "Deployments output directory contains files. Leaving in place...";
    else
      echo "Deployment outputs directory is empty. Removing it...";
      rm -rf $DEPLOYMENT_OUTPUTS_DIR;
  fi
}

display-end-of-run-outputs () {
  echo;
  echo "---";
  echo "Server name: $SERVER_NAME";

  if [ "$ALLOW_SSH_RULE" -eq 0 ]
    then
      echo "Server private FQDN: $SERVER_FQDN";
  fi

  echo "Server public IP: $PUBLIC_IP";
  echo "Deployment name: $DEPLOYMENT_NAME";

  if [ -d "$DEPLOYMENT_OUTPUTS_DIR" ]
    then
      echo "Deployment outputs directory: $DEPLOYMENT_OUTPUTS_DIR";
  fi

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

  # create outputs directory
  create-local-deployment-outputs-dir;

  # log into admin account and record host key
  login-to-admin-acct;

  # perform setups for core platform and user elected features
  perform-core-setup;
  perform-spot-setup;
  perform-openvpn-setup;
  perform-samba-setup;
  perform-dev-tools-setup;  

  # restart server to prove configuration, restart services and run on updated kernel as needed
  # enqueue for 1 minute after execution to give clean up script time to execute
  run-script-from-admin-home restart.sh;

  # clean up the remote home folder
  run-script-from-admin-home clean-up.sh;

  # remove the allow SSH rule if needed (OpenVPN and AllowSsh were both true)
  close-ssh-nsg-rule-if-needed;

  # remove deployment outputs directory if empty
  remove-empty-deployment-outputs-dir;

  # display deployment results to user
  display-end-of-run-outputs;

  echo "---";
  echo "Done.";
  echo;
}

time main $@;
