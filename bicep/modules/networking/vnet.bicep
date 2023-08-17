@description('Region for the resources. Allowed values include US regions.')
@allowed([
  'centralus'
  'eastus'
  'eastus2'
  'eastus3'
  'northcentralus'
  'southcentralus'
  'westcentralus'
])
param location string

@description('Name of the virtual network resource.')
param vnetName string = 'personal-network-vnet'

@description('Address space for the virtual network.')
param vnetAddressSpace string = '10.1.0.0/16'

@description('Address space for the default subnet.')
param defaultSubnetAddressSpace string = '10.1.0.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: defaultSubnetAddressSpace
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

@description('Resource id for the virtual network.')
output vnetId string = vnet.id
