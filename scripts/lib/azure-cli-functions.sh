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

