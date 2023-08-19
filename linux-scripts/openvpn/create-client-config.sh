#!/usr/bin/env bash

# ensure this script has two arguments
if [ "$#" -ne 2 ]
  then
    echo "ERROR: This script must be run with two positional arguments: <CN> and <remoteDNS>. Exiting...";
    echo;
    exit 1;
  else
    CLIENT_CERT_CN="$1";
    REMOTE_DNS="$2";
fi

if [ "$CLIENT_CERT_CN" == "" ]
  then
    echo "ERROR: No client certificate common name provided.";
    exit 1;
fi

if [ "$REMOTE_DNS" == "" ]
  then
    echo "ERROR: No remote server DNS name provided.";
    exit 1;
fi

OPENVPN_DIR="/etc/openvpn/";
BASE_CONFIG="${OPENVPN_DIR}/base-client-config.ovpn";
EASY_RSA_DIR="${OPENVPN_DIR}/easy-rsa/";
EASY_RSA_BIN="${EASY_RSA_DIR}/easyrsa";

KEY_DIR="${EASY_RSA_DIR}/pki/private/";
CERT_DIR="${EASY_RSA_DIR}/pki/issued/";

generate-client-certificate () {
  if [ ! -f ${CERT_DIR}/${CLIENT_CERT_CN}.crt ]
  then
    echo "INFO: Generating client keys...";
    echo "INFO: You will be prompted for the CA passphrase if the CA was encrypted.";

    CURRENT_PWD=$(pwd); # Save current working directory to run later
    cd ${EASY_RSA_DIR};

    sudo $EASY_RSA_BIN build-client-full ${CLIENT_CERT_CN} nopass;
    if [ $? -ne 0 ]
    then
      echo "ERROR: Error running easyrsa. Exiting.";
      exit 1;
    fi

    cd ${CURRENT_PWD}; # Return to old working directory
  else
    echo "WARN: Client key of the same name has been found. Using that key...";
  fi
}

generate-client-configuration-file () {
  local CLIENT_VPN_FILE="${CLIENT_CERT_CN}.ovpn";

  if [ ! -f ${OPENVPN_DIR}/ca.crt ]; 
    then
      echo "ERROR: CA certificate not found";
      exit 1;
  fi

  if sudo test ! -f ${CERT_DIR}/${CLIENT_CERT_CN}.crt; 
    then
      echo "ERROR: User certificate not found";
      exit 1;
  fi

  if sudo test ! -f ${KEY_DIR}/${CLIENT_CERT_CN}.key; 
    then
      echo "ERROR: User private key not found";
      exit 1;
  fi

  if [ ! -f ${OPENVPN_DIR}/ta.key ]; 
    then
      echo "ERROR: TLS Auth key not found";
      exit 1;
  fi

  echo "INFO: Generating client configuration file...";

  touch $CLIENT_VPN_FILE;

  sudo cat ${BASE_CONFIG} > $CLIENT_VPN_FILE;
  echo "remote ${REMOTE_DNS} 1194" >> $CLIENT_VPN_FILE;
  echo "<ca>" >> $CLIENT_VPN_FILE;
  sudo cat ${OPENVPN_DIR}/ca.crt >> $CLIENT_VPN_FILE;
  echo "</ca>" >> $CLIENT_VPN_FILE;
  echo "<cert>" >> $CLIENT_VPN_FILE;
  sudo cat ${CERT_DIR}/${CLIENT_CERT_CN}.crt >> $CLIENT_VPN_FILE;
  echo "</cert>" >> $CLIENT_VPN_FILE;
  echo "<key>" >> $CLIENT_VPN_FILE;
  sudo cat ${KEY_DIR}/${CLIENT_CERT_CN}.key >> $CLIENT_VPN_FILE;
  echo "</key>" >> $CLIENT_VPN_FILE;
  echo "<tls-auth>" >> $CLIENT_VPN_FILE;
  sudo cat ${OPENVPN_DIR}/ta.key >> $CLIENT_VPN_FILE;
  echo "</tls-auth>" >> $CLIENT_VPN_FILE;

  chmod o-r ${CLIENT_VPN_FILE};

  echo "INFO: Client configuration created in $(pwd)/${CLIENT_VPN_FILE}";
  echo "WARN: Transmit and store this configuration securely.";
  echo "WARN: It contains a private key and a pre-shared secret.";
}

add-cn-to-allowed-clients-file () {
  local ALLOWED_CLIENTS_FILE="/etc/openvpn/allowed_clients";

  sudo echo $CLIENT_CERT_CN | sudo tee -a $ALLOWED_CLIENTS_FILE > /dev/null;
}

main () {
  generate-client-certificate;
  generate-client-configuration-file;
  add-cn-to-allowed-clients-file;

  echo "---";
  echo;

  exit 0;
}

main;

