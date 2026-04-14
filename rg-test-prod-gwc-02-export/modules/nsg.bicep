// Network Security Group Module
// Exports: nsg-test-prod-gwc-001

param location string
param nsgName string
param environment string = 'prod'

// Security rules array (can be customized)
param securityRules array = []

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: securityRules
  }
  tags: {
    environment: environment
  }
}

output nsgId string = networkSecurityGroup.id
output nsgName string = networkSecurityGroup.name
