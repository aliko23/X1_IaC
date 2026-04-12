using './main.bicep'

// Deployment parameters for Java Function App with Private Endpoint and VNet Injection
// Development environment

param location = 'eastus'
param environment = 'dev'
param applicationName = 'javaFunc'

// Virtual Network configuration
param vnetConfig = {
  addressPrefix: '10.0.0.0/16'
  functionAppSubnetPrefix: '10.0.1.0/24'
  privateEndpointSubnetPrefix: '10.0.2.0/24'
}

// Storage configuration
param storageSku = 'Standard_LRS'

// App Service Plan configuration
param appServicePlanSku = 'P1v2'

// Java runtime configuration
param javaVersion = '17'

// Capacity
param capacity = 1

// Tags
param tags = {
  environment: 'dev'
  createdBy: 'Bicep'
  application: 'javaFunc'
  owner: 'DevTeam'
  costCenter: 'Engineering'
}
