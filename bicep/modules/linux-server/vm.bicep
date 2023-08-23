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

@description('Admin account user name.')
param adminUsername string

@description('Resource Id of the NIC to associate with the virtual machine.')
param nicId string

@description('Size for the virtual machine.')
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

@description('Indicates if this vm instance should be a spot instance.')
param isSpot bool = true

@description('Public key of the admin user.')
param adminPublicKeyData string

@description('Resource id of a data disk.')
param dataDiskId string

// configuration properties required for spot instance creation
var spotConfig = {
  priority: 'Spot'
  evictionPolicy: 'Deallocate'
  billingProfile: {
    maxPrice: -1
  }
}

// configuration properties required for standard instance creation
var standardConfig = {
  priority: 'Regular'
}

// core virtual machine properties
var coreVmProperties = {
  hardwareProfile: {
    vmSize: vmSize
  }
  storageProfile: {
    imageReference: {
      publisher: 'canonical'
      offer: '0001-com-ubuntu-server-jammy'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    osDisk: {
      osType: 'Linux'
      name: '${serverName}_OsDisk'
      createOption: 'FromImage'
      caching: 'ReadWrite'
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
      deleteOption: 'Delete'
      diskSizeGB: 32
    }
    dataDisks: []
    diskControllerType: 'SCSI'
  }
  osProfile: {
    computerName: serverName
    adminUsername: adminUsername
    linuxConfiguration: {
      disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminPublicKeyData
            }
          ]
        }
      provisionVMAgent: true
      patchSettings: {
        patchMode: 'ImageDefault'
        assessmentMode: 'ImageDefault'
      }
      enableVMAgentPlatformUpdates: false
    }
    secrets: []
    allowExtensionOperations: true
  }
  securityProfile: {
    uefiSettings: {
      secureBootEnabled: true
      vTpmEnabled: true
    }
    encryptionAtHost: true
    securityType: 'TrustedLaunch'
  }
  networkProfile: {
    networkInterfaces: [
      {
        id: nicId
        properties: {
          deleteOption: 'Delete'
        }
      }
    ]
  }
  diagnosticsProfile: {
    bootDiagnostics: {
      enabled: true
    }
  }
}

var dataDiskProperties = {
  storageProfile: {
    dataDisks: [
      {
        lun: 0
        createOption: 'Attach'
        deleteOption: 'Delete'
        caching: 'None'
        managedDisk: {
          id: dataDiskId
        }
      }
    ]
  }
}

var propertiesBeforeDataDisk = isSpot ? union(coreVmProperties, spotConfig) : union(coreVmProperties, standardConfig)
var propertiesWithOptionalDataDisk = empty(dataDiskId) ? propertiesBeforeDataDisk : union(propertiesBeforeDataDisk, dataDiskProperties)

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: serverName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: propertiesWithOptionalDataDisk
}

resource AADSSHLoginForLinuxExtension 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: virtualMachine
  name: 'AADSSHLoginForLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADSSHLoginForLinux'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}
