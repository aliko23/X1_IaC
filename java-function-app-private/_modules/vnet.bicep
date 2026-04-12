// Virtual Network module with subnets for Function App vnet injection and private endpoints

@description('Location for all resources')
param location string

@description('Name of the virtual network')
param vnetName string

@description('Address space for the virtual network')
param addressPrefix string

@description('Name of the subnet for Function App vnet injection')
param functionAppSubnetName string

@description('Address prefix for Function App subnet')
param functionAppSubnetPrefix string

@description('Name of the subnet for private endpoints')
param privateEndpointSubnetName string

@description('Address prefix for private endpoint subnet')
param privateEndpointSubnetPrefix string

@description('Resource tags')
param tags object

// Create Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: functionAppSubnetName
        properties: {
          addressPrefix: functionAppSubnetPrefix
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
          ]
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
  tags: tags
}

// Output subnet IDs
output vnetId string = vnet.id
output vnetName string = vnet.name
output functionAppSubnetId string = '${vnet.id}/subnets/${functionAppSubnetName}'
output privateEndpointSubnetId string = '${vnet.id}/subnets/${privateEndpointSubnetName}'
