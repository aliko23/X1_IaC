// Virtual Machine Module
// Creates a Windows VM with monitoring and security extensions

param location string
param vmName string
param nicId string
param tags object = {}

// Compute specifications
param vmSize string = 'Standard_D2s_v3'

// OS and Image
param osType string = 'Windows'
param imageId string = '' // Resource ID of custom image
param publisher string = '' // e.g., 'MicrosoftWindowsServer'
param offer string = '' // e.g., 'WindowsServer'
param sku string = ''   // e.g., '2022-Datacenter'
param version string = 'latest'
param licenseType string = '' // 'Windows_Client' or 'Windows_Server'

// Storage
param osDiskName string
param osDiskSizeGb int = 128
param osDiskStorageType string = 'Premium_LRS'
param deleteOsDiskOnDelete bool = true

// Admin Credentials
@minLength(1)
@maxLength(20)
param adminUsername string
@minLength(12)
@secure()
param adminPassword string

// Monitoring
param monitoringEnabled bool = true
param monitoringWorkspaceId string = ''
@secure()
param monitoringWorkspaceKey string = ''

// Additional Configuration
param enableHotSpare bool = false
param enableUltraSSD bool = false

// Extensions configuration
param installMonitoringAgent bool = true
param installPolicyExtension bool = true
param installMDEExtension bool = true
param protectedSettingsMonitoringAgent object = {}
param protectedSettingsPolicyExtension object = {}
param protectedSettingsMDEExtension object = {}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: tags
  zones: []
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    storageProfile: {
      imageReference: !empty(imageId) ? {
        id: imageId
      } : {
        publisher: publisher
        offer: offer
        sku: sku
        version: version
      }
      osDisk: {
        name: osDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: osDiskSizeGb
        managedDisk: {
          storageAccountType: osDiskStorageType
        }
        deleteOption: deleteOsDiskOnDelete ? 'Delete' : 'Detach'
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
          properties: {
            primary: true
            deleteOption: 'Detach'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      encryptionIdentity: null
      encryptionAtHost: false
      securityType: 'TrustedLaunch'
    }
  }
}

// Azure Monitor Windows Agent Extension
resource monitoringAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (installMonitoringAgent && monitoringEnabled) {
  name: 'AzureMonitorWindowsAgent'
  parent: virtualMachine
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.18'
    autoUpgradeMinorVersion: true
    protectedSettings: !empty(protectedSettingsMonitoringAgent) ? protectedSettingsMonitoringAgent : {
      workspaceKey: monitoringWorkspaceKey
    }
    settings: {
      workspaceId: monitoringWorkspaceId
      authentication: {
        managedIdentity: {
          enabled: true
        }
      }
    }
  }
}

// Azure Policy Extension for Windows
resource policyExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (installPolicyExtension) {
  name: 'AzurePolicyforWindows'
  parent: virtualMachine
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.29'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    protectedSettings: !empty(protectedSettingsPolicyExtension) ? protectedSettingsPolicyExtension : {}
    settings: {}
  }
}

// Microsoft Defender for Endpoint Extension
resource mdeExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (installMDEExtension) {
  name: 'MDE.Windows'
  parent: virtualMachine
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.AzureDefenderForServers'
    type: 'MDE.Windows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    protectedSettings: !empty(protectedSettingsMDEExtension) ? protectedSettingsMDEExtension : {}
    settings: {}
  }
}

output vmId string = virtualMachine.id
output vmName string = virtualMachine.name
output principalId string = virtualMachine.identity.principalId
