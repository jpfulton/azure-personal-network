validate-az-cli-install () {
  which az > /dev/null;
  if [ "$?" -ne 0 ]
    then
      echo "Azure CLI not found. Please install the Azure CLI. Exiting...";
      exit 1;
  fi
}

run-az-login() {
  echo "Running interactive Azure CLI login...";
  az login;
  if [ $? -ne 0 ]
    then
      echo "Azure Login failed. Exiting.";
      exit 1;
  fi

  echo;
}

check-signed-in-user () {
  echo "Checking for current Azure User:";
  az ad signed-in-user show;
  if [ $? -ne 0 ]
    then
      echo "Azure Login required...";
      run-az-login;
  fi
  
  echo;
}

az-get-vm-resource-id () {
  if [ "$#" -ne 2 ]
    then
      echo "ERROR: az-add-tag function requires 2 arguments. Exiting...";
      echo "INFO:  Required argument one: resource group";
      echo "INFO:  Required argument two: vm name";
      echo;

      exit 1;
  fi

  local RESOURCE_GROUP="$1";
  local VM_NAME="$2";

  local VM_ID=$(az vm list --resource-group $RESOURCE_GROUP --query "[?name=='${VM_NAME}'].id" -o tsv);
  echo $VM_ID;
}

az-add-tag-to-resource () {
  if [ "$#" -ne 2 ]
    then
      echo "ERROR: az-add-tag-to-resource function requires 2 arguments. Exiting...";
      echo "INFO:  Required argument one: resource ID";
      echo "INFO:  Required argument two: Tag key/value pair";
      echo;

      exit 1;
  fi

  local RESOURCE_ID="$1";
  local TAG_PAIR="$2";

  echo "Adding tag to resource...";

  az tag update --resource-id $RESOURCE_ID --operation Merge --tags $TAG_PAIR

  echo;
}

az-create-resource-group () {
  if [ "$#" -ne 2 ]
    then
      echo "ERROR: az-create-resource-group function requires two arguments. Exiting...";
      echo "INFO:  Required argument one: resource group name";
      echo "INFO:  Required argument two: resource group location";
      echo;

      exit 1;
  fi

  local RG_NAME="$1";
  local LOCATION="$2";

  if [ $(az group exists --name $RG_NAME ) = false ]
    then
      az group create --name $RG_NAME --location $LOCATION;
    else
      echo "WARN: Resource group (${RG_NAME}) exists. Continuing...";
  fi
}

# THIS FUNCTION IS INTERACTIVE FOR SAFETY
az-delete-resource-group () {
  if [ "$#" -ne 1 ]
    then
      echo "ERROR: az-delete-resource-group function requires one argument. Exiting...";
      echo "INFO:  Required argument one: resource group name";
      echo;

      exit 1;
  fi

  local RG_NAME="$1";

  echo "WARN: Deleting the ${RG_NAME} resource group will delete all the resources it contains!";
  echo;
  read -p "Re-type the name of the resource group (${RG_NAME}) to confirm: " CONFIRM_PROMPT;

  if [ "$RG_NAME" = "$CONFIRM_PROMPT" ]
    then
      echo "Resource group deletion confirmed. Continuing...";
    else
      echo "Confirm prompt did not match name of resource group. Exiting...";
      exit 1;
  fi

  if [ $(az group exists --name $RG_NAME ) = true ]
    then
      echo "Deleting resource group and all contained resources...";

      az group delete \
        -n $RG_NAME \
        --force-deletion-types Microsoft.Compute/virtualMachines \
        --yes;
    else
      echo "WARN: Resource group (${RG_NAME}) does not exist. Continuing...";
  fi

  echo;
}