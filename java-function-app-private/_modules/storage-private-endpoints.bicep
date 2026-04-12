// Storage Account Private Endpoints module
// Creates private endpoints for all storage services: blob, files, tables, and queues

@description('Location for the private endpoints')
param location string

@description('Name prefix for private endpoints')
param privateEndpointNamePrefix string

@description('Resource ID of the Storage Account')
param storageAccountId string

@description('Subnet ID where private endpoints will be deployed')
param subnetId string

@description('Resource tags')
param tags object

// Extract storage account name from resource ID
var storageAccountName = last(split(storageAccountId, '/'))

// Create Private Endpoint for Blob service
resource blobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: '${privateEndpointNamePrefix}-blob'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointNamePrefix}-blob-connection'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'blob'
          ]
          requestMessage: 'Auto-Provisioned PE for Storage Blob'
        }
      }
    ]
  }
  tags: tags
}

// Create Private Endpoint for File service
resource filePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: '${privateEndpointNamePrefix}-file'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointNamePrefix}-file-connection'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'file'
          ]
          requestMessage: 'Auto-Provisioned PE for Storage File Share'
        }
      }
    ]
  }
  tags: tags
}

// Create Private Endpoint for Table service
resource tablePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: '${privateEndpointNamePrefix}-table'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointNamePrefix}-table-connection'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'table'
          ]
          requestMessage: 'Auto-Provisioned PE for Storage Table'
        }
      }
    ]
  }
  tags: tags
}

// Create Private Endpoint for Queue service
resource queuePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: '${privateEndpointNamePrefix}-queue'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointNamePrefix}-queue-connection'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'queue'
          ]
          requestMessage: 'Auto-Provisioned PE for Storage Queue'
        }
      }
    ]
  }
  tags: tags
}

// Output Private Endpoint details
output blobEndpointId string = blobPrivateEndpoint.id
output blobEndpointName string = blobPrivateEndpoint.name
output fileEndpointId string = filePrivateEndpoint.id
output fileEndpointName string = filePrivateEndpoint.name
output tableEndpointId string = tablePrivateEndpoint.id
output tableEndpointName string = tablePrivateEndpoint.name
output queueEndpointId string = queuePrivateEndpoint.id
output queueEndpointName string = queuePrivateEndpoint.name
output storageAccountName string = storageAccountName
