// Virtual Network Module
// Exports: hedno-vnet-test-prod-gwc-02 with subnets and VNet peerings

param location string
param vnetName string
param addressPrefix string
param dnsServers array
param nsgId string
param routeTableId string
param environment string = 'prod'

// Subnet configuration
param subnetName string = 'snet-test-prod-gwc-001'
param subnetAddressPrefix string

// VNet Peering configurations
param vnetPeeringConfigs array = [
  {
    peeringName: 'hedno-vnet-test-prod-gwc-02-to-hedno-hub-germanywest'
    remoteVnetId: '/subscriptions/95eff073-0a30-4add-b30b-fade9c017ea6/resourceGroups/hedno-vnethub-germanywestcentral-001/providers/Microsoft.Network/virtualNetworks/hedno-hub-germanywest'
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
  }
  {
    peeringName: 'vnetpeer-hedno-vnet-test-prod-gwc-02-to-vnet-ipnet-hub-gwc-01'
    remoteVnetId: '/subscriptions/95eff073-0a30-4add-b30b-fade9c017ea6/resourceGroups/rg-ipnet-hub-gwc-01/providers/Microsoft.Network/virtualNetworks/vnet-ipnet-hub-gwc-01'
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: true
  }
]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: dnsServers
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsgId
          }
          routeTable: {
            id: routeTableId
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
  }
  tags: {
    environment: environment
  }
}

// VNet Peerings
resource vnetPeerings 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = [for (peering, index) in vnetPeeringConfigs: {
  parent: virtualNetwork
  name: peering.peeringName
  properties: {
    allowForwardedTraffic: peering.allowForwardedTraffic
    allowGatewayTransit: peering.allowGatewayTransit
    allowVirtualNetworkAccess: peering.allowVirtualNetworkAccess
    doNotVerifyRemoteGateways: false
    peerCompleteVnets: true
    remoteVirtualNetwork: {
      id: peering.remoteVnetId
    }
    useRemoteGateways: peering.useRemoteGateways
  }
}]

output vnetId string = virtualNetwork.id
output vnetName string = virtualNetwork.name
output subnetId string = '${virtualNetwork.id}/subnets/${subnetName}'
output subnetName string = subnetName
