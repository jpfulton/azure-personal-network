using './linux-server.bicep'

param isSpot = bool(readEnvironmentVariable('IS_SPOT', 'true'))
param serverName = readEnvironmentVariable('SERVER_NAME')
param vmSize = readEnvironmentVariable('VM_SIZE')
param adminUsername = readEnvironmentVariable('ADMIN_USERNAME')
param adminPublicKeyData = readEnvironmentVariable('ADMIN_PUBLIC_KEY')
param allowSsh = bool(readEnvironmentVariable('ALLOW_SSH', 'false'))
