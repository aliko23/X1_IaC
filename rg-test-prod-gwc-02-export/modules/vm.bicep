// Virtual Machine Module
// Exports: vmtestprod001

param location string
param vmName string
param vmSize string = 'Standard_B2as_v2'
param nicIds array
param diskId string
param adminUsername string
param zones array = ['1']
param environment string = 'prod'

// OS Configuration
param computerName string = vmName
param enableAutomaticUpdates bool = true
param patchMode string = 'AutomaticByPlatform'
param assessmentMode string = 'AutomaticByPlatform'
param enableHotpatching bool = false

// Image reference
param imagePublisher string = 'MicrosoftWindowsServer'
param imageOffer string = 'WindowsServer'
param imageSku string = '2022-datacenter-azure-edition'
param imageExactVersion string = '20348.3932.250705'

// Monitoring and diagnostics
param bootDiagnosticsEnabled bool = true
param enableSystemAssignedIdentity bool = true

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  zones: zones
  identity: enableSystemAssignedIdentity ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageExactVersion
      }
      osDisk: {
        createOption: 'Attach'
        managedDisk: {
          id: diskId
        }
        caching: 'ReadWrite'
        deleteOption: 'Delete'
        osType: 'Windows'
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
      windowsConfiguration: {
        enableAutomaticUpdates: enableAutomaticUpdates
        provisionVMAgent: true
        patchSettings: {
          patchMode: patchMode
          assessmentMode: assessmentMode
          enableHotpatching: enableHotpatching
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
            bypassPlatformSafetyChecksOnUserSchedule: true
          }
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
    }
    networkProfile: {
      networkInterfaces: [for (nicId, index) in nicIds: {
        id: nicId
        properties: {
          primary: index == 0
          deleteOption: 'Delete'
        }
      }]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: bootDiagnosticsEnabled
      }
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
  }
  tags: {
    environment: environment
  }
}

output vmId string = virtualMachine.id
output vmName string = virtualMachine.name
output vmPrincipalId string = enableSystemAssignedIdentity ? virtualMachine.identity.principalId : ''
