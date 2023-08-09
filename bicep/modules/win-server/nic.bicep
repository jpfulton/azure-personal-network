param serverName string

param location string

param vnetName string
param subnetName string = 'default'

var publicIpAddressName = '${serverName}-public-ip'
var publicIPAddressType = 'Dynamic'

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  sku: {
    name: 'Basic'
  }
  name: publicIpAddressName
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: publicIPAddressType
  }
}

var networkSecurityGroupName = '${serverName}-nsg'

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: []
  }
}

var networkInterfaceName = '${serverName}-nic'

resource nic 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

@description('The id of the nic resource.')
output nicId string = nic.id
