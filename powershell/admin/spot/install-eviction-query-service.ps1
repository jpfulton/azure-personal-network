
$ProgressPreference = 'SilentlyContinue'

$SERVICE_NAME="Azure Spot Instance Eviction Service"

$SERVICE_VERSION="v0.0.8"
$SERVICE_ARCHIVE_NAME="binaries-win-x64-${SERVICE_VERSION}.zip"
$SERVICE_URL="https://github.com/jpfulton/short-interval-scheduler-service/releases/download/${SERVICE_VERSION}/${SERVICE_ARCHIVE_NAME}"

$SCRIPT_NAME="query-for-preempt-event.ps1"
$SCRIPT_URL="https://raw.githubusercontent.com/jpfulton/azure-personal-network/main/powershell/local/${SCRIPT_NAME}"

$SERVICE_INSTALL_DIR="$env:ProgramFiles\SpotEvictionQueryService"
$SERVICE_FULL_EXE_PATH="${SERVICE_INSTALL_DIR}\Jpfulton.ShortIntervalScheduler.exe"

$SCRIPT_FULL_PATH="${SERVICE_INSTALL_DIR}\${SCRIPT_NAME}"
$SERVICE_CMD="powershell.exe ${SCRIPT_FULL_PATH}"

Remove-Item -Force "$env:TEMP\${SERVICE_ARCHIVE_NAME}" -ErrorAction SilentlyContinue
Remove-Item -Force "$env:TEMP\${SCRIPT_NAME}" -ErrorAction SilentlyContinue

Invoke-WebRequest -Uri $SERVICE_URL -OutFile "$env:TEMP\${SERVICE_ARCHIVE_NAME}"
Invoke-WebRequest -Uri $SCRIPT_URL -OutFile "$env:TEMP\${SCRIPT_NAME}"

New-Item -ItemType Directory -Path $SERVICE_INSTALL_DIR -Force

Expand-Archive -Force -Path "$env:TEMP\${SERVICE_ARCHIVE_NAME}" -DestinationPath $SERVICE_INSTALL_DIR

Move-Item -Force -Path "$env:TEMP\${SCRIPT_NAME}" -Destination $SERVICE_INSTALL_DIR

$existingService = Get-Service -Name $SERVICE_NAME -ErrorAction SilentlyContinue
if ($existingService) {
  sc.exe delete "${SERVICE_NAME}"
}
New-Service -Name $SERVICE_NAME -BinaryPathName "`"${SERVICE_FULL_EXE_PATH}`" `"${SERVICE_CMD}`" 10" -StartupType Automatic
Start-Service -Name $SERVICE_NAME
