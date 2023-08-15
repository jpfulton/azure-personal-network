# Install the Azure Spot Instance Eviction Service
$ProgressPreference = 'SilentlyContinue'

$SERVICE_NAME="Azure Spot Instance Eviction Service"

$SERVICE_VERSION="v0.0.13"
$SERVICE_ARCHIVE_NAME="binaries-win-x64-${SERVICE_VERSION}.zip"
$SERVICE_URL="https://github.com/jpfulton/short-interval-scheduler-service/releases/download/${SERVICE_VERSION}/${SERVICE_ARCHIVE_NAME}"

$SCRIPT_NAME="query-for-preempt-event.ps1"
$SCRIPT_URL="https://raw.githubusercontent.com/jpfulton/azure-personal-network/main/powershell/local/${SCRIPT_NAME}"

# Use short path to avoid space parsing issues (e.g. C:\Program~1\)
$fs = New-Object -ComObject Scripting.FileSystemObject
$PROGRAM_FILES_SHORTPATH=($fs.GetFolder("${env:ProgramFiles}").ShortPath)
$SERVICE_INSTALL_DIR="${PROGRAM_FILES_SHORTPATH}\SpotEvictionQueryService"
$SERVICE_FULL_EXE_PATH="${SERVICE_INSTALL_DIR}\Jpfulton.ShortIntervalScheduler.exe"

$SCRIPT_FULL_PATH="${SERVICE_INSTALL_DIR}\${SCRIPT_NAME}"
$SERVICE_CMD="powershell.exe -File ${SCRIPT_FULL_PATH}"

# Stop and remove any existing instances of the service
$existingService = Get-Service -Name $SERVICE_NAME -ErrorAction SilentlyContinue
if ($existingService) {
  Stop-Service -Name $SERVICE_NAME
  sc.exe delete "${SERVICE_NAME}"
}

# Remove the old binaries directory and any temp files laying around
Remove-Item -Force $SERVICE_INSTALL_DIR -ErrorAction SilentlyContinue -Recurse
Remove-Item -Force "$env:TEMP\${SERVICE_ARCHIVE_NAME}" -ErrorAction SilentlyContinue
Remove-Item -Force "$env:TEMP\${SCRIPT_NAME}" -ErrorAction SilentlyContinue

# Download the service binaries and PS script
Invoke-WebRequest -Uri $SERVICE_URL -OutFile "$env:TEMP\${SERVICE_ARCHIVE_NAME}"
Invoke-WebRequest -Uri $SCRIPT_URL -OutFile "$env:TEMP\${SCRIPT_NAME}"

# Create the service folder
New-Item -ItemType Directory -Path $SERVICE_INSTALL_DIR -Force

# Unpack the archive of binaries
Expand-Archive -Force -Path "$env:TEMP\${SERVICE_ARCHIVE_NAME}" -DestinationPath $SERVICE_INSTALL_DIR

# Install the PS script
Move-Item -Force -Path "$env:TEMP\${SCRIPT_NAME}" -Destination $SERVICE_INSTALL_DIR

# Install and start the service
New-Service -Name $SERVICE_NAME `
  -BinaryPathName "`"${SERVICE_FULL_EXE_PATH}`" `"${SERVICE_CMD}`" 5" `
  -StartupType Automatic

Start-Service -Name $SERVICE_NAME
