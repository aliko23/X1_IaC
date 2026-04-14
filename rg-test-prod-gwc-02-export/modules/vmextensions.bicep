// VM Extensions Module
// Deploys monitoring and security extensions to virtual machine

param vmId string
param vmName string
param location string

// Azure Monitor Windows Agent Extension
resource monitorWindowsAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: '${vmName}/AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      authentication: {
        managedIdentity: {
          'identifier-name': 'mi_res_id'
          'identifier-value': '/subscriptions/${subscription().subscriptionId}/resourceGroups//providers/Microsoft.ManagedIdentity/userAssignedIdentities/'
        }
      }
    }
  }
}

// Azure Policy for Windows Extension
resource policyWindowsExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: '${vmName}/AzurePolicyforWindows'
  location: location
  dependsOn: [
    monitorWindowsAgentExtension
  ]
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.1'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
  }
}

// Defender for Servers Extension
resource defenderExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: '${vmName}/MDE.Windows'
  location: location
  dependsOn: [
    policyWindowsExtension
  ]
  properties: {
    publisher: 'Microsoft.Azure.AzureDefenderForServers'
    type: 'MDE.Windows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
    forceUpdateTag: '034017a3-c49f-453a-b641-b4aacc1a9248'
    settings: {
      autoUpdate: true
      azureResourceId: vmId
      forceReOnboarding: false
      vNextEnabled: true
    }
  }
}

output monitorExtensionId string = monitorWindowsAgentExtension.id
output policyExtensionId string = policyWindowsExtension.id
output defenderExtensionId string = defenderExtension.id
