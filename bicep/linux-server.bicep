@description('Bool to determine if the vm will be created as a spot instance.')
param isSpot bool = true

@description('Name for the virtual machine.')
param serverName string

@description('Size for the virtual machine. Allowed SKUs support nested virtualization for the WSL.')
@allowed([
  'Standard_DS1_v2'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS5_v2'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_D16s_v3'
  'Standard_D32s_v3'
  'Standard_D48s_v3'
  'Standard_D64s_v3'
])
param vmSize string = 'Standard_DS1_v2'

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

@description('Public key data for the admin user.')
param adminPublicKeyData string

@description('Create allow SSH inbound NSG rule.')
param allowSsh bool = false

@description('Create an inbound allow OpenVPN rule.')
param allowOpenVpn bool = false

@description('Create and attach data disk.')
param addDataDisk bool = false

module nicModule 'modules/nic.bicep' = {
  name: 'nic-deploy'
  params: {
    location: location
    serverName: serverName
    vnetName: vnetName
    allowSsh: allowSsh
    allowOpenVpn: allowOpenVpn
  }
}

var dataDiskName = '${serverName}-data-disk'

module dataDiskModule 'modules/data-disk.bicep' = if (addDataDisk) {
  name: 'data-disk-deploy'
  params: {
    location: location
    name: dataDiskName
    diskSize: 512
  }
}

module vmModule 'modules/linux-server/vm.bicep' = {
  name: 'vm-deploy'
  params: {
    adminUsername: adminUsername
    adminPublicKeyData: adminPublicKeyData
    location: location
    nicId: nicModule.outputs.nicId
    serverName: serverName
    vmSize: vmSize
    isSpot: isSpot
    dataDiskId: empty(dataDiskModule) ? '' : dataDiskModule.outputs.diskId
  }
}

@description('Public IP of the server.')
output publicIp string = nicModule.outputs.publicIp
