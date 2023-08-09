run-ps () {
  if [ $# -ne 3 ]
    then
      echo "ERROR: run-ps function requires 3 arguments. Exiting...";
      echo "INFO:  Required arguement one: Resource Group.";
      echo "INFO:  Required arguement two: Virtual Machine Name.";
      echo "INFO:  Required arguement one: Path to Powershell Script.";
      echo;

      exit 1;
  fi

  RESOURCE_GROUP="$1";
  SERVER_NAME="$2";
  PS_FILE="$3";

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