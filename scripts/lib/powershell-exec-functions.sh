validate-local-ps-install () {
  which pwsh > /dev/null;
  if [ "$?" -ne 0 ]
    then
      echo "Local Powershell installationn not found. Please install Powershell. Exiting...";
      exit 1;
  fi
}

run-azure-ps () {
  if [ "$#" -ne 3 ]
    then
      echo "ERROR: run-ps function requires 3 arguments. Exiting...";
      echo "INFO:  Required arguement one: Resource Group.";
      echo "INFO:  Required arguement two: Virtual Machine Name.";
      echo "INFO:  Required arguement one: Path to Powershell Script.";
      echo;

      exit 1;
  fi

  local RESOURCE_GROUP="$1";
  local SERVER_NAME="$2";
  local PS_FILE="$3";

  if [ ! -f $PS_FILE ]
    then
      echo "ERROR: Powershell script not found. Exiting...";
      echo;

      exit 1;
  fi

  az vm run-command invoke \
    --command-id RunPowerShellScript \
    --name $SERVER_NAME \
    -g $RESOURCE_GROUP \
    --scripts @${PS_FILE};

  echo "---";
  echo;
}

run-local-ps () {
  if [ "$#" -lt 1 ]
    then
      echo "ERROR: run-local-ps function requires at least one argument. Exiting...";
      echo "INFO:  Required arguement one: Powershell file.";
      echo "INFO:  Optional arguement: Arguments as string.";
      echo;

      exit 1;
  fi

  local PS_FILE="$1";
  local ARGS="$2";

  if [ ! -f $PS_FILE ]
    then
      echo "ERROR: Powershell script not found. Exiting...";
      echo;

      exit 1;
  fi

  pwsh -File $PS_FILE $ARGS;

  echo "---";
  echo;
}

run-ps-as-admin () {
  if [ "$#" -ne 4 ]
    then
      echo "ERROR: run-ps-as-admin function requires four arguments. Exiting...";
      echo "INFO:  Required arguement one: Local remote exection shell Powershell file.";
      echo "INFO:  Required arguement two: Powershell file for remote execution.";
      echo "INFO:  Required arguement three: Admin username.";
      echo "INFO:  Required arguement four: Server host name.";
      echo;

      exit 1;
  fi

  local LOCAL_SHELL_FILE="$1";
  local PS_FILE="$2";
  local USERNAME="$3";
  local HOSTNAME="$4";

  if [ ! -f $LOCAL_SHELL_FILE ]
    then
      echo "ERROR: Local shell Powershell script not found. Exiting...";
      echo;

      exit 1;
  fi

  if [ ! -f $PS_FILE ]
    then
      echo "ERROR: Remote Powershell script not found. Exiting...";
      echo;

      exit 1;
  fi

  pwsh -File $LOCAL_SHELL_FILE -username $USERNAME -hostname $HOSTNAME -remotescript $PS_FILE;

  echo "---";
  echo;
}