param subnetName string
param addressPrefix string
param vnetName string
param location string
param nsgId string

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' = {
  name: '${vnetName}/${subnetName}'
  properties: {
    addressPrefix: addressPrefix
    networkSecurityGroup: {
      id: nsgId
    }
  }
}
