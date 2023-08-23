@description('Name for the data disk.')
param name string

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

@description('Size in GB of disk.')
@allowed([
  32
  64
  128
  256
  512
  1024
  2048
  4096
  8192
])
param diskSize int = 512

resource dataDisk 'Microsoft.Compute/disks@2023-01-02' = {
  name: name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: diskSize
    encryption: {
      type: 'EncryptionAtRestWithPlatformKey'
    }
    networkAccessPolicy: 'DenyAll'
    publicNetworkAccess: 'Disabled'
    dataAccessAuthMode: 'None'
  }
}

@description('Resource id of the data disk.')
output diskId string = dataDisk.id
