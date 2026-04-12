// Main orchestration file for Java Function App with Private Endpoint and VNet Injection
// This template deploys a complete Java Function App infrastructure with:
// - Virtual Network with dedicated subnets for Function App and Private Endpoints
// - Storage Account (required backend storage)
// - App Service Plan (Linux-based for Java)
// - Java 17 Function App with VNet integration
// - Private Endpoint for secure connectivity

targetScope = 'resourceGroup'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, staging, prod)')
param environment string = 'dev'

@description('Application name prefix for naming resources')
param applicationName string

@description('Virtual Network configuration')
param vnetConfig object = {
  addressPrefix: '10.0.0.0/16'
  functionAppSubnetPrefix: '10.0.1.0/24'
  privateEndpointSubnetPrefix: '10.0.2.0/24'
}

@description('Storage Account SKU')
param storageSku string = 'Standard_LRS'

@description('App Service Plan SKU')
param appServicePlanSku string = 'P1v2'

@description('Java version')
@allowed([
  '8'
  '11'
  '17'
  '21'
])
param javaVersion string = '17'

@description('Capacity (number of instances)')
param capacity int = 1

@description('Resource tags')
param tags object = {
  environment: environment
  createdBy: 'Bicep'
  createdDate: utcNow('u')
  application: applicationName
}

// Generate unique names following Azure naming conventions
var uniqueSuffix = uniqueString(resourceGroup().id)
var storageAccountName = replace('${toLower(applicationName)}${toLower(environment)}st${uniqueSuffix}', '-', '')
var vnetName = '${applicationName}-${environment}-vnet'
var functionAppSubnetName = '${applicationName}-${environment}-func-subnet'
var privateEndpointSubnetName = '${applicationName}-${environment}-pe-subnet'
var appServicePlanName = '${applicationName}-${environment}-asp'
var functionAppName = '${applicationName}-${environment}-func-${uniqueSuffix}'
var privateEndpointName = '${applicationName}-${environment}-func-pe'

// Module to deploy Virtual Network
module vnetModule '_modules/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
    vnetName: vnetName
    addressPrefix: vnetConfig.addressPrefix
    functionAppSubnetName: functionAppSubnetName
    functionAppSubnetPrefix: vnetConfig.functionAppSubnetPrefix
    privateEndpointSubnetName: privateEndpointSubnetName
    privateEndpointSubnetPrefix: vnetConfig.privateEndpointSubnetPrefix
    tags: tags
  }
}

// Module to deploy Storage Account
module storageModule '_modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    storageAccountName: storageAccountName
    storageSku: storageSku
    tags: tags
  }
}

// Module to deploy App Service Plan
module appServicePlanModule '_modules/app-service-plan.bicep' = {
  name: 'appServicePlanDeployment'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    skuName: appServicePlanSku
    capacity: capacity
    kind: 'Linux'
    tags: tags
  }
}

// Module to deploy Function App with VNet integration
module functionAppModule '_modules/function-app.bicep' = {
  name: 'functionAppDeployment'
  params: {
    location: location
    functionAppName: functionAppName
    appServicePlanId: appServicePlanModule.outputs.appServicePlanId
    storageAccountConnectionString: storageModule.outputs.storageAccountConnectionString
    vnetSubnetId: vnetModule.outputs.functionAppSubnetId
    javaVersion: javaVersion
    runtimeStack: 'JAVA|${javaVersion}'
    httpsOnly: true
    tags: tags
  }
}

// Module to deploy Private Endpoint for Function App
module privateEndpointModule '_modules/private-endpoint.bicep' = {
  name: 'privateEndpointDeployment'
  params: {
    location: location
    privateEndpointName: privateEndpointName
    functionAppId: functionAppModule.outputs.functionAppId
    subnetId: vnetModule.outputs.privateEndpointSubnetId
    privateLinkConnectionName: '${privateEndpointName}-connection'
    groupIds: [
      'sites'
    ]
    tags: tags
  }
}

// Module to deploy Private Endpoints for Storage Account services
module storagePrivateEndpointsModule '_modules/storage-private-endpoints.bicep' = {
  name: 'storagePrivateEndpointsDeployment'
  params: {
    location: location
    privateEndpointNamePrefix: '${applicationName}-${environment}-storage'
    storageAccountId: storageModule.outputs.storageAccountId
    subnetId: vnetModule.outputs.privateEndpointSubnetId
    tags: tags
  }
}

// Outputs
@description('Resource IDs and connection details')
output deploymentDetails object = {
  vnetId: vnetModule.outputs.vnetId
  vnetName: vnetModule.outputs.vnetName
  storageAccountId: storageModule.outputs.storageAccountId
  storageAccountName: storageModule.outputs.storageAccountName
  appServicePlanId: appServicePlanModule.outputs.appServicePlanId
  functionAppId: functionAppModule.outputs.functionAppId
  functionAppName: functionAppModule.outputs.functionAppName
  functionAppUrl: functionAppModule.outputs.functionAppUrl
  functionAppPrivateEndpointId: privateEndpointModule.outputs.privateEndpointId
  storagePrivateEndpoints: {
    blobEndpointId: storagePrivateEndpointsModule.outputs.blobEndpointId
    fileEndpointId: storagePrivateEndpointsModule.outputs.fileEndpointId
    tableEndpointId: storagePrivateEndpointsModule.outputs.tableEndpointId
    queueEndpointId: storagePrivateEndpointsModule.outputs.queueEndpointId
  }
  functionAppPrincipalId: functionAppModule.outputs.functionAppPrincipalId
}
output storagePrivateEndpoints object = {
  blob: storagePrivateEndpointsModule.outputs.blobEndpointName
  file: storagePrivateEndpointsModule.outputs.fileEndpointName
  table: storagePrivateEndpointsModule.outputs.tableEndpointName
  queue: storagePrivateEndpointsModule.outputs.queueEndpointName
}

output functionAppResourceId string = functionAppModule.outputs.functionAppId
output functionAppName string = functionAppModule.outputs.functionAppName
output functionAppUrl string = functionAppModule.outputs.functionAppUrl
output vnetId string = vnetModule.outputs.vnetId
output storageAccountName string = storageModule.outputs.storageAccountName
