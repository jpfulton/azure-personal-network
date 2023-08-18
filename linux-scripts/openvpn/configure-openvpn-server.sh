#!/usr/bin/env bash

BASE_REPO_URL="https://raw.githubusercontent.com/jpfulton/example-linux-configs/main";

if [ "$#" -ne 3 ]
  then
    echo "ERROR: This script requires three arguments. Exiting...";
    echo "INFO:  Required argument one: Address space of virtual network. (10.10.0.0)";
    echo "INFO:  Required argument two: Subnet for VPN clients. (10.10.8.0)";
    echo "INFO:  Required argument three: Public IP or Public DNS of VPN server.";
    echo;

    exit 1;
fi

VNET_ADDRESS_SPACE="$1";
VPN_SUBNET="$2";
PUBLIC_SERVER_ADDRESS="$3";

setup-openvpn-support-scripts () {
  # Set up OpenVPN scripts if OpenVPN is installed
  local OPENVPN_DIR="/etc/openvpn/";
  local BASE_CLIENT_CONFIG="base-client-config.ovpn";
  local CLIENT_CONFIG_SCRIPT="create-client-ovpn-config.sh";
  local OPENVPN_SCRIPTS_DIR="/etc/openvpn/scripts/";
  local CONNECT_SCRIPT="on-connect.sh";
  local DISCONNECT_SCRIPT="on-disconnect.sh";
  local VERIFY_SCRIPT="on-tls-verify.sh";

  if [ -d $OPENVPN_DIR ]
    then
      echo "OpenVPN configuration folder exists.";

      echo "Installing OpenVPN client template...";
      sudo wget -q ${BASE_REPO_URL}${OPENVPN_DIR}${BASE_CLIENT_CONFIG};
      sudo mv ./${BASE_CLIENT_CONFIG} ${OPENVPN_DIR}${BASE_CLIENT_CONFIG};

      echo "Installing OpenVPN scripts...";
      if [ ! -d $OPENVPN_SCRIPTS_DIR ]
        then
          echo "Creating scripts directory.";
          sudo mkdir $OPENVPN_SCRIPTS_DIR;
      fi

      sudo wget -q ${BASE_REPO_URL}${OPENVPN_SCRIPTS_DIR}${CONNECT_SCRIPT};
      sudo chmod a+x ./${CONNECT_SCRIPT};
      sudo mv ./${CONNECT_SCRIPT} ${OPENVPN_SCRIPTS_DIR}${CONNECT_SCRIPT};

      sudo wget -q ${BASE_REPO_URL}${OPENVPN_SCRIPTS_DIR}${DISCONNECT_SCRIPT};
      sudo chmod a+x ./${DISCONNECT_SCRIPT};
      sudo mv ./${DISCONNECT_SCRIPT} ${OPENVPN_SCRIPTS_DIR}${DISCONNECT_SCRIPT};

      sudo wget -q ${BASE_REPO_URL}${OPENVPN_SCRIPTS_DIR}${VERIFY_SCRIPT};
      sudo chmod a+x ./${VERIFY_SCRIPT};
      sudo mv ./${VERIFY_SCRIPT} ${OPENVPN_SCRIPTS_DIR}${VERIFY_SCRIPT};

      echo "---";
      echo;
  fi
}

setup-allowed-clients-file () {
  local ALLOWED_CLIENTS_FILE="/etc/openvpn/allowed_clients";
  sudo touch $ALLOWED_CLIENTS_FILE;
  sudo echo "# Allowed Client Certificate CNs" | sudo tee $ALLOWED_CLIENTS_FILE > /dev/null;
}

create-server-config-and-start () {
  local OPENVPN_DIR="/etc/openvpn/";
  local BASE_SERVER_CONFIG="base-server-config.conf";
  local SERVICE_NAME="personal-network-server";
  local SERVER_CONFIG="${SERVICE_NAME}.conf";

  wget -q ${BASE_REPO_URL}${OPENVPN_DIR}${BASE_SERVER_CONFIG};

  echo "server $VPN_SUBNET 255.255.255.0" >> $BASE_SERVER_CONFIG;
  echo "push \"route $VNET_ADDRESS_SPACE 255.255.0.0\"" >> $BASE_SERVER_CONFIG;

  sudo mv ./${BASE_SERVER_CONFIG} ${OPENVPN_DIR}${SERVER_CONFIG};
  sudo chown root:root ${OPENVPN_DIR}${SERVER_CONFIG};

  sudo systemctl start openvpn@${SERVICE_NAME};
}

configure-firewall () {
  local UFW_BEFORE_RULES_FILE="/etc/ufw/before.rules";

  echo "Configuring local firewall for OpenVPN...";

  sudo ufw allow proto udp from 0.0.0.0/0 to any port 1194;
  sudo ufw route allow in on tun0 out on eth0;
  sudo ufw status numbered;

  local NAT_RULES="
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Forward traffic through eth0 - Change to match you out-interface
-A POSTROUTING -s ${VPN_SUBNET}/24 -o eth0 -j MASQUERADE
# don't delete the 'COMMIT' line or these nat table rules won't
# be processed
COMMIT
# End NAT table rules";

  local ORIGINAL_CONTENT=$(sudo cat $UFW_BEFORE_RULES_FILE);

  sudo mv $UFW_BEFORE_RULES_FILE "${UFW_BEFORE_RULES_FILE}.backup";

  touch before.rules;
  echo "$NAT_RULES" > before.rules;
  echo "$ORIGINAL_CONTENT" >> before.rules;
  sudo mv before.rules $UFW_BEFORE_RULES_FILE;
  sudo chown root:root $UFW_BEFORE_RULES_FILE;
  sudo chmod g-w $UFW_BEFORE_RULES_FILE;

  sudo ufw disable;
  sudo ufw --force enable;
}

setup-allowed-clients-file;
setup-openvpn-support-scripts;
create-server-config-and-start;
configure-firewall;
