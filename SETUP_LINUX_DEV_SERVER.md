# Setup a Linux Development Server

In this guide, a Linux development server will be created with the following
features:

- A minimal installation of Gnome Desktop
- An xRDP server allowing access to the desktop environment using an RDP client
- Git
- Nodejs v18
- Nodejs Corepack Enabled
- Yarn package manager
- .NET 7 SDK
- Google Chrome
- VS Code

## Install a Local RDP Client

For macOS, use the App Store to install the
[Microsoft Remote Desktop Client](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466?mt=12).

## Create a Linux Development Server

From the root of this repository navigate to the control scripts folder in
a terminal with the command:

```bash
cd scripts
```

The next command creates a Linux development server with the features listed
above. An account name and initial randomly generated password will be securely transferred
to a deployment outputs folder in your local account's home folder in file named
`dev-users.txt`. The output folder will be located in the current local
user's home folder and will be labeled `deployment-outputs-{UUID}`. Output lines
at the end of the script will identify this folder.

Instead of selecting the default virtual machine size, select a larger version
for this installation: `Standard_DS2_v2`. A two core instance with a larger RAM
profile will make the system more responsive for the desktop environment.

```bash
./create-linux-server.sh -d personal-network linux-dev
```

## Log into the Server via RDP

Open the Microsoft Remote Desktop App, and from the **Connections** menu select
**Add PC**. In the **Add PC** dialog, enter `linux-dev.yourprivatednszonehere.com` as
the PC name. In the User account drop down, select **Add a User Account**, in the next
step enter the credentials found in `dev-users.txt` within the deployment outputs folder.
Select **Add** and then select **Add** in the Add PC dialog accepting the default settings
for the connection. The new machine will be visible in the main application window. Double
click the connection to log into the Linux server.
