@description('Server name for the virtual machine.')
param serverName string

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

@description('Name of the virtual network to associate with.')
param vnetName string

@description('Subnet name with the specified virtual network to attach to.')
param subnetName string = 'default'

@description('Create an inbound allow SSH rule.')
param allowSsh bool = false

@description('Create an inbound allow OpenVPN rule.')
param allowOpenVpn bool = false

var publicIpAddressName = '${serverName}-public-ip'
var publicIPAddressType = 'Static'

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  sku: {
    name: 'Standard'
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

var nsgSshRuleName = '${networkSecurityGroupName}/AllowSsh'

resource nsgRuleAllowSsh 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (allowSsh) {
  name: nsgSshRuleName
  properties: {
    access: 'Allow'
    direction: 'Inbound'
    priority: 100
    protocol: 'Tcp'
    description: 'Allow SSH Inbound'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '22'
  }
  dependsOn: [
    nsg
  ]
}

var nsgOpenVpnRuleName = '${networkSecurityGroupName}/AllowOpenVpn'

resource nsgRuleAllowOpenVpn 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (allowOpenVpn) {
  name: nsgOpenVpnRuleName
  properties: {
    access: 'Allow'
    direction: 'Inbound'
    priority: 200
    protocol: 'Udp'
    description: 'Allow OpenVpn Inbound'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '1194'
  }
  dependsOn: [
    nsg
  ]
}

var networkInterfaceName = '${serverName}-nic'

resource nic 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
            properties: {
              deleteOption: 'Delete'
            }
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

@description('Public IP assocated with the NIC.')
output publicIp string = publicIp.properties.ipAddress
