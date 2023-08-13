@description('Server name for the virtual machine.')
@maxLength(15)
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

@secure()
@description('Password for the admin account.')
param adminPassword string

@description('Resource Id of the NIC to associate with the virtual machine.')
param nicId string

@description('Size for the virtual machine. Allowed SKUs support nested virtualization for the WSL.')
@allowed([
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_D16s_v3'
  'Standard_D32s_v3'
  'Standard_D48s_v3'
  'Standard_D64s_v3'
])
param vmSize string = 'Standard_D2s_v3'

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: serverName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition-smalldisk'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
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
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
    }
    securityProfile: {
      encryptionAtHost: true
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
    priority: 'Spot'
    evictionPolicy: 'Deallocate'
    billingProfile: {
      maxPrice: -1
    }
  }
}

resource aadLoginExtension 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: virtualMachine
  name: 'AADLoginForWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}

