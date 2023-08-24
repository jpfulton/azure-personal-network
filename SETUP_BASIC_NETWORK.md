# Setup a Basic Personal Network

Follow the prerequisite steps and installations from the main repository
[README](./README.md).

From the root of this repository navigate to the control scripts folder with
the command:

```bash
cd scripts
```

## Create and Configure a Resource Group

```bash
./create-resource-group.sh personal-network northcentralus
```

## Create the Virtual Network and Private DNS Zone

```bash
./create-network.sh personal-network
```

## Create an OpenVPN Server

```bash
./create-linux-server.sh -s -o personal-network vpn-server
```

Install client opvn config to Tunnelblick from deployment folder

## Create a Samba Backup Server

```bash
./create-linux-server.sh -b personal-network backup-server
```

## Connect Time Machine to the Backup Server

Open the deployment folder
Pull the password for applebackup
Open Finder > Go to Server... > Enter Private FQDN and copied password
Open Settings > Time Machine > Add Share > Select AppleBackups share > Start Backup
