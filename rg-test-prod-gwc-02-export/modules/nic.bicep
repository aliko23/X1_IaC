// Network Interface Module
// Exports: vmtestprod001196_z1

param location string
param nicName string
param subnetId string
param environment string = 'prod'
param enableAcceleratedNetworking bool = true
param enableIPForwarding bool = false
param privateIPAllocationMethod string = 'Dynamic'
param privateIPAddress string = ''

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          primary: true
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: privateIPAllocationMethod
          privateIPAddress: !empty(privateIPAddress) ? privateIPAddress : null
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableIPForwarding: enableIPForwarding
    networkSecurityGroup: null
  }
  tags: {
    environment: environment
  }
}

output nicId string = networkInterface.id
output nicName string = networkInterface.name
output primaryIPConfig string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
