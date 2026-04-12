// App Service Plan module for hosting Java Function App

@description('Location for the App Service Plan')
param location string

@description('Name of the App Service Plan')
param appServicePlanName string

@description('SKU for the App Service Plan')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
  'P1v3'
  'P2v3'
  'P3v3'
  'EP1'
  'EP2'
  'EP3'
])
param skuName string = 'P1v2'

@description('Number of worker instances')
param capacity int = 1

@description('Type of App Service Plan (Windows or Linux)')
@allowed([
  'Windows'
  'Linux'
])
param kind string = 'Linux'

@description('Resource tags')
param tags object

// Create App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  kind: kind
  sku: {
    name: skuName
    capacity: capacity
  }
  properties: {
    reserved: kind == 'Linux' ? true : false
  }
  tags: tags
}

// Output App Service Plan details
output appServicePlanId string = appServicePlan.id
output appServicePlanName string = appServicePlan.name
