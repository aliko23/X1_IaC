param location string
param vnetName string
param addressPrefix string
param subnetName string
param subnetPrefix string
param nsgName string

module nsg 'modules/nsg.bicep' = {
  name: 'nsgModule'
  params: {
    nsgName: nsgName
    location: location
  }
}

module vnet 'modules/vnet.bicep' = {
  name: 'vnetModule'
  params: {
    vnetName: vnetName
    location: location
    addressPrefix: addressPrefix
  }
}

module subnet 'modules/subnet.bicep' = {
  name: 'subnetModule'
  params: {
    subnetName: subnetName
    addressPrefix: subnetPrefix
    vnetName: vnetName
    location: location
    nsgId: nsg.outputs.nsgId
  }
}
