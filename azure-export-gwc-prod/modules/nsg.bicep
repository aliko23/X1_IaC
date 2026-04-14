// Network Security Group Module
// Creates NSG with configurable inbound and outbound rules

param location string
param nsgName string
param tags object = {}

// Security rules configuration
param securityRules array = []

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      for (rule, index) in securityRules: {
        name: rule.name
        properties: {
          description: rule.?description ?? ''
          protocol: rule.protocol
          sourcePortRange: rule.?sourcePortRange ?? '*'
          destinationPortRange: rule.?destinationPortRange ?? '*'
          sourceAddressPrefix: rule.?sourceAddressPrefix ?? '*'
          destinationAddressPrefix: rule.?destinationAddressPrefix ?? '*'
          sourceAddressPrefixes: rule.?sourceAddressPrefixes ?? []
          destinationAddressPrefixes: rule.?destinationAddressPrefixes ?? []
          access: rule.access
          priority: rule.priority
          direction: rule.direction
        }
      }
    ]
  }
}

output nsgId string = networkSecurityGroup.id
output nsgName string = networkSecurityGroup.name
