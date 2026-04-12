// Private Endpoint module for secure access to Function App

@description('Location for the private endpoint')
param location string

@description('Name of the private endpoint')
param privateEndpointName string

@description('Resource ID of the Function App')
param functionAppId string

@description('Subnet ID where private endpoint will be deployed')
param subnetId string

@description('Name of the private link connection')
param privateLinkConnectionName string = '${privateEndpointName}-plink'

@description('Group ID for the private endpoint service')
param groupIds array = [
  'sites'
]

@description('Resource tags')
param tags object

// Create Private Endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnectionName
        properties: {
          privateLinkServiceId: functionAppId
          groupIds: groupIds
          requestMessage: 'Auto-Provisioned PE for Function App'
        }
      }
    ]
  }
  tags: tags
}

// Output Private Endpoint details
output privateEndpointId string = privateEndpoint.id
output privateEndpointName string = privateEndpoint.name
output privateEndpointNetworkInterfaces array = privateEndpoint.properties.networkInterfaces
