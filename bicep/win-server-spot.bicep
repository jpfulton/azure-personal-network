@description('Name for the virtual machine.')
@maxLength(15)
param serverName string

@description(
'''Region for the virtual machine and associated resources.
Allowed values include US regions.
Defaults to the region of the resource group.
'''
)
param location string = resourceGroup().location

@description('Name of the virtual network for this VM to attach to.')
param vnetName string = 'personal-network-vnet'

@description('Admin username.')
param adminUsername string = 'jpfulton'

@description('Admin user account password.')
@secure()
param adminPassword string

module nicModule 'modules/win-server/nic.bicep' = {
  name: 'nic-deploy'
  params: {
    location: location
    serverName: serverName
    vnetName: vnetName
  }
}

module vmModule 'modules/win-server/vm.bicep' = {
  name: 'vm-deploy'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    location: location
    nicId: nicModule.outputs.nicId
    serverName: serverName
  }
}
