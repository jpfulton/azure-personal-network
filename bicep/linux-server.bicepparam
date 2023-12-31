using './linux-server.bicep'

param isSpot = bool(readEnvironmentVariable('IS_SPOT', 'true'))
param serverName = readEnvironmentVariable('SERVER_NAME')
param vmSize = readEnvironmentVariable('VM_SIZE')
param adminUsername = readEnvironmentVariable('ADMIN_USERNAME')
param adminPublicKeyData = readEnvironmentVariable('ADMIN_PUBLIC_KEY')
param allowSsh = bool(readEnvironmentVariable('ALLOW_SSH', 'false'))
param allowOpenVpn = bool(readEnvironmentVariable('ALLOW_OPENVPN', 'false'))
param addDataDisk = bool(readEnvironmentVariable('ADD_DATA_DISK', 'false'))
param addStorageAccount = bool(readEnvironmentVariable('ADD_STORAGE_ACCOUNT', 'false'))
param storageAccountName = readEnvironmentVariable('STORAGE_ACCOUNT_NAME', '')
