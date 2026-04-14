// Virtual Network Module
// Creates a VNet with configurable address spaces and DNS settings

param location string
param vnetName string
param addressPrefixes array
param dnsServers array = []
param tags object = {}

// Subnets configuration
param subnets array = []

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    dhcpOptions: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          networkSecurityGroup: !empty(subnet.nsgId) ? {
            id: subnet.nsgId
          } : null
          routeTable: !empty(subnet.routeTableId) ? {
            id: subnet.routeTableId
          } : null
          privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies ?? 'Disabled'
          privateLinkServiceNetworkPolicies: subnet.?privateLinkServiceNetworkPolicies ?? 'Enabled'
        }
      }
    ]
  }
}

output vnetId string = virtualNetwork.id
output vnetName string = virtualNetwork.name
