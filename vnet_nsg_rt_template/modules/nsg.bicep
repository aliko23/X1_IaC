metadata name = 'Network Security Group Module'
metadata description = 'Creates a Network Security Group with default security rules'

@minLength(1)
@maxLength(80)
@description('Name of the NSG')
param nsgName string

@description('Azure region for the NSG')
param location string

@description('Tags to apply to the NSG')
param tags object = {}

@description('Array of security rules to add to the NSG')
param securityRules array = [
  {
    name: 'AllowVnetInbound'
    priority: 100
    direction: 'Inbound'
    access: 'Allow'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'VirtualNetwork'
  }
  {
    name: 'AllowAzureLoadBalancerInbound'
    priority: 110
    direction: 'Inbound'
    access: 'Allow'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceAddressPrefix: 'AzureLoadBalancer'
    destinationAddressPrefix: '*'
  }
  {
    name: 'DenyAllInbound'
    priority: 4096
    direction: 'Inbound'
    access: 'Deny'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
  }
  {
    name: 'AllowVnetOutbound'
    priority: 100
    direction: 'Outbound'
    access: 'Allow'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'VirtualNetwork'
  }
  {
    name: 'AllowInternetOutbound'
    priority: 110
    direction: 'Outbound'
    access: 'Allow'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: 'Internet'
  }
]

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      for rule in securityRules: {
        name: rule.name
        properties: {
          protocol: rule.protocol
          sourcePortRange: rule.sourcePortRange
          destinationPortRange: rule.destinationPortRange
          sourceAddressPrefix: rule.sourceAddressPrefix
          destinationAddressPrefix: rule.destinationAddressPrefix
          access: rule.access
          priority: rule.priority
          direction: rule.direction
        }
      }
    ]
  }
}

@description('The resource ID of the Network Security Group')
output nsgId string = nsg.id

@description('The name of the Network Security Group')
output nsgName string = nsg.name
