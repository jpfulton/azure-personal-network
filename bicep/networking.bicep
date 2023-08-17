@description('Region for the resources. Allowed values include US regions.')
param location string = resourceGroup().location

@description('Name of the virtual network resource.')
param vnetName string = 'personal-network-vnet'

@description('Address space for the virtual network.')
param vnetAddressSpace string = '10.1.0.0/16'

@description('Address space for the default subnet.')
param defaultSubnetAddressSpace string = '10.1.0.0/24'

@description('Name of the private DNS zone to create for the network.')
param privateDnsZoneName string = 'test.jpatrickfulton.com'

module vnetModule 'modules/networking/vnet.bicep' = {
  name: 'vnet-deploy'
  params: {
    location: location
    vnetName: vnetName
    vnetAddressSpace: vnetAddressSpace
    defaultSubnetAddressSpace: defaultSubnetAddressSpace
  }
}

module privateDnsModule 'modules/networking/private-dns.bicep' = {
  name: 'private-dns-deploy'
  params: {
    vnetId: vnetModule.outputs.vnetId
    vnetName: vnetName
    zoneName: privateDnsZoneName
  }
}
