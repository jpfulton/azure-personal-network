validate-sshpass-install () {
  which sshpass > /dev/null;
  if [ "$?" -ne 0 ]
    then
      echo "sshpass utility not found. Please install sshpass. Exiting...";
      echo "INFO: A script to install the sshpass utility is available in the /scripts/ folder.";
      exit 1;
  fi
}