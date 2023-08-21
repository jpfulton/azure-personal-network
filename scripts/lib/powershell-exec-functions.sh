validate-local-ps-install () {
  which pwsh > /dev/null;
  if [ "$?" -ne 0 ]
    then
      echo "Local Powershell installationn not found. Please install Powershell. Exiting...";
      exit 1;
  fi
}

run-azure-ps () {
  if [ "$#" -lt 3 ]
    then
      echo "ERROR: run-ps function requires at least 3 arguments. Exiting...";
      echo "INFO:  Required argument one: Resource Group.";
      echo "INFO:  Required argument two: Virtual Machine Name.";
      echo "INFO:  Required argument three: Path to Powershell Script.";
      echo "INFO:  Optional argument four: [--no-wait] to indicate no waiting on the script to complete";
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

  if [ "$4" = "--no-wait" ]
    then
      echo "INFO: Long running script will be executed without a wait in background.";
      ENABLE_NO_WAIT="--no-wait";
    else
      ENABLE_NO_WAIT="";
  fi

  az vm run-command invoke \
    --command-id RunPowerShellScript \
    --name $SERVER_NAME \
    -g $RESOURCE_GROUP \
    --scripts @${PS_FILE} $ENABLE_NO_WAIT;

  echo "---";
  echo;
}

run-local-ps () {
  if [ "$#" -lt 1 ]
    then
      echo "ERROR: run-local-ps function requires at least one argument. Exiting...";
      echo "INFO:  Required argument one: Powershell file.";
      echo "INFO:  Optional argument: Arguments as string.";
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
  if [ "$#" -lt 4 ]
    then
      echo "ERROR: run-ps-as-admin function requires four arguments. Exiting...";
      echo "INFO:  Required argument one: Local remote exection shell Powershell file.";
      echo "INFO:  Required argument two: Powershell file for remote execution.";
      echo "INFO:  Required argument three: Admin username.";
      echo "INFO:  Required argument four: Server host name.";
      echo "INFO:  Optional argument five: Args to powershell script.";
      echo;

      exit 1;
  fi

  local LOCAL_SHELL_FILE="$1";
  local PS_FILE="$2";
  local USERNAME="$3";
  local HOSTNAME="$4";
  shift 4;
  local ARGS="$@";

  if [ ! -f $LOCAL_SHELL_FILE ]
    then
      echo "ERROR: Local shell Powershell script not found. Exiting...";
      echo;

      exit 1;
  fi

  if [ "$PS_FILE" = "" ]
    then
      echo "ERROR: Remote Powershell script empty. Exiting...";
      echo;

      exit 1;
  fi

  pwsh -File $LOCAL_SHELL_FILE -username $USERNAME -hostname $HOSTNAME -remotescript $PS_FILE -scriptargs "$ARGS";

  echo "---";
  echo;
}