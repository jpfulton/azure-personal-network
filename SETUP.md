# Setup

Follow main README.

cd scripts

./create-resource-group.sh personal-network northcentralus
./create-network.sh personal-network
./create-linux-server.sh -s -o personal-network vpn-server
