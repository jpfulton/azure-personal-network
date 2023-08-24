# Setup a Basic Personal Network

Follow the prerequisite steps and installation instructions from the main repository
[README](./README.md).

From the root of this repository navigate to the control scripts folder in
a terminal with the command:

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

Next, create a Linux virtual machine running Samba server with a configuration that
supports macOS Time Machine backups. This configuration will take place across the
the VPN tunnel with the following command. A data disk to store the backup data will
be created, formatted and mounted into the Linux file system in this step.

Note that this data disk will be configured for deletion with the virtual machine be default
should you run the `/delete-vm.sh` script against the virtual machine. You may wish
to take a snapshot of the data disk prior to deleting the virtual machine should
you wish to retain and data stored there prior to removing the virtual machine.

Randomly generated passwords for Samba share access will be securely transferred to a new deployment outputs folder in your home directory at the end of the process. The final outputs of the script
will show the name of the deployment outputs folder from this step. Note that it will have
a different name than the output folder from the previous step.

```bash
./create-linux-server.sh -b personal-network backup-server
```

## Connect Time Machine to the Backup Server

Using the Finder, navigate to the new deployment outputs folder and in an editor
of your choice open the `samba-users.txt`. Copy the randomly generated password
associated with the `applebackup` account to the clip board.

From the **Finder** > **Go** menu select **Connect to Server...\*** to open a server
connection dialog. Enter the Samba address of the newly created backup server:

```bash
smb://backup-server.yourprivatednszonehere.com
```

Click connect. Enter `applebackup` for the username and paste the password into the
password field. Select the checkbox to retain this username and password key on your
key chain. In the next step, select the `applebackups` share as the volume to mount.
The Finder will open an show the contents of the share. It will be empty if the share
has not yet been used.

To connect Time Machine to the remote share, open the **System Settings** application.
Select **General** > **Time Machine**. Click the **Plus** button to add a backup target.
Choose the `applebackups` share from the next dialog and click **Set Up Disk**.

In the next dialog, ensure that you elect to encrypt your backup files with a password.
Enter a password for the backup of your choosing and confirm it prior to moving to the
next step. You will need this password in the future should you need to use these backup
files from another workstation in a recovery operation. Memorize it and store it in a safe
place. It is not added to the key chain.

Once the disk has been set up, the backup will begin in 60 seconds. The first backup operation
is complete and may take some time. Future backup operations are incremental and significantly
faster.
