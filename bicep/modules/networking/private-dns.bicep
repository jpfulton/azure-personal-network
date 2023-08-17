@description('The zone name of the private DNS zone.')
param zoneName string

@description('Name of the virtual network to link to the private DNS zone.')
param vnetName string

@description('Resource ID of the virtual network to link to the private DNS zone.')
param vnetId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: zoneName
  location: 'global'
  properties: {
  }
}

resource soaRecord 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: privateDnsZone
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

var linkName = '${vnetName}-link'

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZone
  name: linkName
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnetId
    }
  }
}
