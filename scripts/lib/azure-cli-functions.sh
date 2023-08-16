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

az-add-tag-to-resource () {
  if [ "$#" -ne 2 ]
    then
      echo "ERROR: az-add-tag function requires 2 arguments. Exiting...";
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

