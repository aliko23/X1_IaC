// Network Interface Module
// Creates a network interface card with IP configuration

param location string
param nicName string
param subnetId string
param tags object = {}

// IP Configuration
param primaryPrivateIpAddress string = ''
param ipConfigName string = 'ipconfig1'
param enableAcceleratedNetworking bool = false
param nsgId string = ''
param publicIpId string = ''
param enableIpForwarding bool = false

// DNS Settings
param dnsServers array = []

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableIPForwarding: enableIpForwarding
    networkSecurityGroup: !empty(nsgId) ? {
      id: nsgId
    } : null
    dnsSettings: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
    ipConfigurations: [
      {
        name: ipConfigName
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAddress: !empty(primaryPrivateIpAddress) ? primaryPrivateIpAddress : null
          privateIPAllocationMethod: !empty(primaryPrivateIpAddress) ? 'Static' : 'Dynamic'
          publicIPAddress: !empty(publicIpId) ? {
            id: publicIpId
          } : null
          primary: true
        }
      }
    ]
  }
}

output nicId string = networkInterface.id
output nicName string = networkInterface.name
output primaryPrivateIp string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
