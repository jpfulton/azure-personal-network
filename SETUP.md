# Setup

Follow main README.

cd scripts

./create-resource-group.sh personal-network northcentralus
./create-network.sh personal-network
./create-linux-server.sh -s -o personal-network vpn-server

Install client opvn config to Tunnelblick from deployment folder

./create-linux-server.sh -b personal-network backup-server

Open the deployment folder
Pull the password for applebackup
Open Finder > Go to Server... > Enter Private FQDN and copied password
Open Settings > Time Machine > Add Share > Select AppleBackups share > Start Backup
