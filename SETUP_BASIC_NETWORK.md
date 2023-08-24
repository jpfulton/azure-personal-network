# Setup a Basic Personal Network

Follow the prerequisite steps and installations from the main repository
[README](./README.md).

From the root of this repository navigate to the control scripts folder with
the command:

```bash
cd scripts
```

## Create and Configure a Resource Group

The following command creates a resource group to host the remaining resources
and configures the current user in the `Virtual Machine Administrator Login` role
for the resource group to allow the current user to access the virtual machines
using Azure AD credentials.

```bash
./create-resource-group.sh personal-network northcentralus
```

## Create the Virtual Network and Private DNS Zone

The following script creates a virtual network with an associated private
DNS zone which is configured to auto-register records for new virtual machines
that attach to the virtual network. The script will prompt for user inputs
for the name of the DNS zone and the address space for the network. In most cases,
the default values for the address space prompts will be sufficient.

```bash
./create-network.sh personal-network
```

## Create an OpenVPN Server

The next command creates a Linux virtual machine to run an OpenVPN server that
will create a tunnel into the virtual network. The installation will initially
be performed over an open SSH port to the public IP address associated with the
virtual machine. Once the installation is complete, the rule allowing SSH connectivity
on the public IP address for the machine is removed. An OpenVPN client configuration
file will be securely transferred to the local workstation and placed in the
deployment output folder. The output folder will be located in the current local
user's home folder and will be labeled `deployment-outputs-{UUID}`. Output lines
at the end of the script will identify this folder.

```bash
./create-linux-server.sh -s -o personal-network vpn-server
```

At this stage, the remaining steps must be performed across the VPN tunnel. To
install the client configuration file, open [Tunnelblick](https://tunnelblick.net/downloads.html)
and use the Finder to navigate to the deployment outputs folder. Drag the OVPN file found
there onto the Tunnelblick icon in the menu bar to install the file. Open the connection from
that application.

Validate that connectivity and access to the private DNS zone is working from the terminal
by pinging the private FQDN of the newly created VPN server.

```bash
ping vpn-server.yourprivatednszonenamehere.com
```

It may be necessary to clear the local workstation's DNS cache and restart the VPN connection
if errors appear from the last command related to name resolution. Use the following command
to clear the local DNS cache if this is the case.

```bash
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

Only proceed to the next step if name resolution for the private dns zone is working.

## Create a Samba Backup Server

```bash
./create-linux-server.sh -b personal-network backup-server
```

## Connect Time Machine to the Backup Server

Open the deployment folder
Pull the password for applebackup
Open Finder > Go to Server... > Enter Private FQDN and copied password
Open Settings > Time Machine > Add Share > Select AppleBackups share > Start Backup
