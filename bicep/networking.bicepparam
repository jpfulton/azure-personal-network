using './networking.bicep'

param vnetName = readEnvironmentVariable('VNET_NAME')
param privateDnsZoneName = readEnvironmentVariable('PRIVATE_DNS_ZONE')
param vnetAddressSpace = readEnvironmentVariable('ADDRESS_SPACE')
param defaultSubnetAddressSpace = readEnvironmentVariable('SUBNET_ADDRESS_SPACE')
