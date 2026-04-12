param nsgName string
param location string

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: nsgName
  location: location
  properties: {}
}

output nsgId string = nsg.id
