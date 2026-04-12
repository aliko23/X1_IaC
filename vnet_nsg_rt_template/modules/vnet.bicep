metadata name = 'Virtual Network Module'
metadata description = 'Creates a Virtual Network with configurable subnets'

@minLength(1)
@maxLength(64)
@description('Name of the Virtual Network')
param vnetName string

@description('Azure region for the Virtual Network')
param location string

@minLength(1)
@maxLength(18)
@description('Address space for the Virtual Network (CIDR notation)')
param addressSpace string

@description('Array of subnet configurations with NSG and Route Table associations')
param subnets array = []

@description('Tags to apply to the Virtual Network')
param tags object = {}

@description('Enable DDoS protection (standard or basic)')
param enableDdosProtection bool = false

@description('Enable VM protection on the Virtual Network')
param enableVmProtection bool = false

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          networkSecurityGroup: {
            id: subnet.nsgId
          }
          routeTable: {
            id: subnet.routeTableId
          }
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: enableDdosProtection
    enableVmProtection: enableVmProtection
  }
}

@description('The resource ID of the Virtual Network')
output vnetId string = vnet.id

@description('The name of the Virtual Network')
output vnetName string = vnet.name

@description('The address prefixes of the Virtual Network')
output addressSpace array = vnet.properties.addressSpace.addressPrefixes

@description('Array of subnet IDs')
output subnetIds array = [
  for i in range(0, length(subnets)): vnet.properties.subnets[i].id
]

@description('Array of subnet names')
output subnetNames array = [
  for i in range(0, length(subnets)): vnet.properties.subnets[i].name
]
