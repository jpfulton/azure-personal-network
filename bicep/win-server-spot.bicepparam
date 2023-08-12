using './win-server-spot.bicep'

param serverName = readEnvironmentVariable('SERVER_NAME')
param adminUsername = readEnvironmentVariable('ADMIN_USERNAME')
param adminPassword = readEnvironmentVariable('ADMIN_PASSWORD')
