targetScope = 'subscription'

// ------------------
//    IMPORTS
// ------------------
import * as my from '../_modules/exports.bicep'

// ------------------
//    PARAMETERS
// ------------------

@description('The name of the workload, used in the naming scheme of the module resources')
param workloadName my.nonEmptyStringType

@allowed([
  'prod'
  'qa'
])
@description('Environment abbreviation used in the naming scheme of the module resources')
param env string 

@description('The selected region of the resources')
param location string = deployment().location

@description('Configuration settings for the APIM VNet')
param vnetSharedConfiguration my.vnetSettingsType

@description('Configuration settings for the APIM')
param apimConfiguration my.apimSettingsType

@description('The Resource ID of the centralized Private DNS Zone for key vault. If not provided, the module will create a new one.')
param keyvaultPrivateDnsZoneId string = '' 

@description('The Resource ID of the centralized Private DNS Zone for Function Apps. If not provided, the module will create a new one.')
param functionAppPrivateDnsZoneId string = '' 

@description('The Resource ID of the centralized Private DNS Zone for cosmosDB. If not provided, the module will create a new one.')
param cosmosDbPrivateDnsZoneId string = ''


// ------------------
// VARIABLES
// ------------------

var tags = {
  environment: env
}

@description('The regions, used in the naming scheme')
var resourceIdentifiers = loadJsonContent('../_configuration/resourceTypeAbbreviations.json')
var dnsZoneConsts = loadJsonContent('../_configuration/private_dns_consts.jsonc')

@description('The ConfigSet values for the Shared resources')
var envConfigMap = loadJsonContent('../_configuration/env_config_set.jsonc')

@description('The NSG Rules for the APIM Subnet')
var apimNSGRules = loadJsonContent('../_configuration/nsg_apim_rules.json', 'securityRules') 

// naming of the resources
var apimName = my.takeSafe(my.getName(resourceIdentifiers.apiManagement, workloadName, env, location, 1), 55)
var pipName = 'pip-${apimName}'
var vnetSharedName = my.takeSafe(my.getName(resourceIdentifiers.virtualNetwork, workloadName, env, location, 1), 64)
var rgSharedName = my.takeSafe(my.getName(resourceIdentifiers.resourceGroup, workloadName, env, location, 1), 90)
var sharedLogWsName = my.takeSafe(my.getName(resourceIdentifiers.logAnalyticsWorkspace, workloadName, env, location, 1), 63)
var appInsightsName = my.takeSafe(my.getName(resourceIdentifiers.applicationInsights, workloadName, env, location, 1), 64)
//----------------- Keyvault section --------------------
var kvName = my.takeSafe(my.getUniqueName(resourceIdentifiers.keyVault, workloadName, env, location, rgShared.id, 1), 24)
var peKvName = '${resourceIdentifiers.privateEndpoint}-${kvName}'
//----------------- CosmosDB section --------------------
var cosmosDbName = my.takeSafe(my.getUniqueName(resourceIdentifiers.cosmosDbNoSql, workloadName, env, location, rgShared.id, 1), 44)
var peCosmosDbName = '${resourceIdentifiers.privateEndpoint}-${cosmosDbName}'
//----------------- Function Apps section --------------------
var aspName = my.takeSafe(my.getName(resourceIdentifiers.appServicePlan, workloadName, env, location, 1), 40)
var functionCount = 3

// ------------------
// RESOURCES
// ------------------

@description('Creates the resource group for the APIM resources')
resource rgShared 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: rgSharedName
  location: location
  tags: tags  
}

@description('The log sink for Azure Diagnostics')
module sharedLogAnalyticsWorkspace '../_modules/monitoring/log-analytics-ws.bicep' = {
  scope: rgShared
  name: my.takeSafe('sharedLogWs-${uniqueString(rgShared.id)}', 64)
  params: {
    location: location
#disable-next-line BCP334
    name: sharedLogWsName
  }
}

@description('Azure Application Insights, the workload\' log & metric sink and APM tool')
module applicationInsights '../_modules/monitoring/app-insights.bicep' ={
  name: my.takeSafe('applicationInsights-${uniqueString(rgShared.id)}', 64)
  scope: rgShared
  params: {
    name: appInsightsName
    location: location
    tags: tags
    workspaceResourceId: sharedLogAnalyticsWorkspace.outputs.logAnalyticsWsId
  }
}

@description('Creates the NSG associated with the APIM')
module nsgApim '../_modules/networking/nsg.bicep' = {
  scope: rgShared
  name:my.takeSafe('nsg-apim-${deployment().name}', 64)  
  params: {
    name: 'nsg-apim'
    location: location
    tags: tags
    securityRules: apimNSGRules    
  }
}

@description('NSG Rules for the Integration subnet.')
module nsgIntegration '../_modules/networking/nsg.bicep' = {
  name: my.takeSafe('nsgIntegration-${deployment().name}', 64)
  scope: rgShared
  params: {
    name: 'nsg-integration'
    location: location
    tags: tags
    securityRules: []
  }
}

@description('NSG Rules for the DevOps subnet.')
module nsgDevops '../_modules/networking/nsg.bicep' = {
  name: my.takeSafe('nsgDevops-${deployment().name}', 64)
  scope: rgShared
  params: {
    name: 'nsg-devops'
    location: location
    tags: tags
    securityRules: []
  }
}

@description('NSG Rules for the private enpoint subnet.')
module nsgPep '../_modules/networking/nsg.bicep' = {
  name: my.takeSafe('nsgPep-${deployment().name}', 64)
  scope: rgShared
  params: {
    name: 'nsg-pep'
    location: location
    tags: tags
    securityRules: []
  }
}

@description('Creates the VNet for the Shared resources')
module vnetShared '../_modules/networking/vnet.bicep' = {
  scope: rgShared
  name: my.takeSafe('vnetShared-${deployment().name}', 64)
  params: {
    name: vnetSharedName
    vnetAddressPrefixes: [vnetSharedConfiguration.addressSpace]
    subnets: [
      for subnet in vnetSharedConfiguration.subnets: {
        name: subnet.name
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: replace(subnet.name, 'snet', 'nsg')
        delegation: subnet.?delegation
        routeTable: subnet.?routeTable
      }
    ]
    location: location
    tags: tags
  }
  dependsOn: [    
    nsgIntegration
    nsgPep
    nsgDevops
  ]  
}

@description('Gets a reference to the newly created VNet and its subnets')
resource vnetSharedCreated 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetSharedName
  scope: rgShared

  resource snetApim 'subnets' existing = {
    name: vnetSharedConfiguration.subnets[0].name
  }

  resource snetSharedIntegration 'subnets' existing = {
    name: vnetSharedConfiguration.subnets[1].name
  }

  resource snetSharedPep 'subnets' existing =  {
    name: vnetSharedConfiguration.subnets[2].name
  }
  
  resource snetSharedDevOps 'subnets' existing = {
    name: vnetSharedConfiguration.subnets[3].name
  }


}

@description('Creates the Public IP for the APIM')
module pipApim '../_modules/Networking/pip.bicep' = {
  scope: rgShared
  name: my.takeSafe('pip-apim-${deployment().name}', 64)
  params: {
    location: location
    tags: tags    
    name: pipName
    domainNameLabel: pipName
  }
}


//----------------- APIM section --------------------

@description('Creates the APIM resource')
module apim '../_modules/compute/apim.bicep' = {
  name: my.takeSafe('apim-${deployment().name}', 64)  
  scope: rgShared
  params: {
    name: apimName
    location: location
    tags: tags    
    apimSubnetId: vnetShared.outputs.vnetSubnets[0].id
    capacity: envConfigMap[env].apim.capacity
    publicIpAddressId: pipApim.outputs.resourceId
    publisherEmail: apimConfiguration.publisherEmail
    publisherName: apimConfiguration.publisherName
    skuName: envConfigMap[env].apim.sku
    virtualNetworkType: 'Internal'
    appInsightsId: applicationInsights.outputs.id
    appInsightsInstrumentationKey: applicationInsights.outputs.instrumentationKey
    diagnosticWorkspaceId: sharedLogAnalyticsWorkspace.outputs.logAnalyticsWsId
  }
}


//----------------- Keyvault section --------------------

@description('Create a KeyVault with a private endpoint in the VNet')
module keyVault '../_modules/security/keyvault.bicep' = {
  name: my.takeSafe('keyvault-${deployment().name}', 64)
  scope: rgShared
  params: {
    name: kvName
    location: location
    enableRbacAuthorization: true
    hasPrivateEndpoint: true
    tags: tags       
    diagnosticWorkspaceId: sharedLogAnalyticsWorkspace.outputs.logAnalyticsWsId
  }
}

module keyvaultPrivateDnsZone '../_modules/networking/private-dns-zone.bicep' = if (empty(keyvaultPrivateDnsZoneId)) {
  name: my.takeSafe('keyvaultPrivateDnsZone-${deployment().name}', 64)
  scope: rgShared
  params: { 
    name: dnsZoneConsts.keyvault.dnsZoneName
    vnetIdsToLink: [vnetShared.outputs.vnetId]
    tags: tags // added tags parameter
  }
}

module keyvaultPrivateEndpoint '../_modules/networking/private-endpoint.bicep' = {
  name: my.takeSafe('keyvaultPrivateEndpoint-${deployment().name}', 64)
  scope: rgShared
  params: {
    name: peKvName
    location: location
    tags: tags
    privateDnsZonesId: empty(keyvaultPrivateDnsZoneId) ? keyvaultPrivateDnsZone.outputs.privateDnsZonesId : keyvaultPrivateDnsZoneId
    privateLinkServiceId: keyVault.outputs.keyvaultId
    snetId: vnetSharedCreated::snetSharedPep.id
    subresource: dnsZoneConsts.keyvault.subResource    
  }  
}


//----------------- CosmosDB section --------------------

@description('Creates a CosmosDB account with a private endpoint in the VNet')
module cosmosDb '../_modules/storage/cosmos-db-no-sql.bicep' = {
  name: my.takeSafe('cosmosDb-${deployment().name}', 64)
  scope: rgShared
  params: {
    name: cosmosDbName
    location: location
    tags: tags
    hasPrivateEndpoint: true
    locations: envConfigMap[env].cosmosDb.accountProperties.locations
    automaticFailover: envConfigMap[env].cosmosDb.accountProperties.enableAutomaticFailover
    containers: envConfigMap[env].cosmosDb.containers   
    diagnosticWorkspaceId: sharedLogAnalyticsWorkspace.outputs.logAnalyticsWsId
  }
}

module cosmosDbPrivateDnsZone '../_modules/networking/private-dns-zone.bicep' = if (empty(cosmosDbPrivateDnsZoneId)) {
  name: my.takeSafe('cosmosDbPrivateDnsZone-${deployment().name}', 64)
  scope: rgShared
  params: {
    name: dnsZoneConsts.cosmosdb.dnsZoneName
    vnetIdsToLink: [vnetShared.outputs.vnetId]
    tags: tags // added tags parameter
  }
}

module cosmosDbPrivateEndpoint '../_modules/networking/private-endpoint.bicep' = {
  name: my.takeSafe('cosmosDbPrivateEndpoint-${deployment().name}', 64)
  scope: rgShared
  params: {
    name: peCosmosDbName
    location: location
    tags: tags
    privateDnsZonesId: empty(cosmosDbPrivateDnsZoneId) ? cosmosDbPrivateDnsZone.outputs.privateDnsZonesId : cosmosDbPrivateDnsZoneId
    privateLinkServiceId: cosmosDb.outputs.resourceId
    snetId: vnetSharedCreated::snetSharedPep.id
    subresource: dnsZoneConsts.cosmosdb.subResource  
  }
}


//----------------- Function Apps section --------------------

module functionUserAssignedManagedIdenity '../_modules/identity/userAssignedManagedIdentity.bicep' =  [for i in range(0, functionCount): {
  name: my.takeSafe('funcUserAssignedManagedIdenity-${padLeft(string(i), 2, '0')}-${deployment().name}', 64)
  scope: rgShared
  params: {
    name: '${resourceIdentifiers.managedIdentity}-${my.takeSafe(my.getUniqueName(resourceIdentifiers.functionApp, workloadName, env, location, rgShared.id, i + 1), 60)}'
    location: location
    tags: tags
  }
}]

module asp '../_modules/compute/app-services/app-service-plan.bicep' = {
  name: my.takeSafe('functionsElasticPlan-${deployment().name}', 64)
  scope: rgShared
  params: {
    name: aspName
    location: location
    sku: envConfigMap[env].functionApp.sku    
    tags: tags
    diagnosticWorkspaceId: sharedLogAnalyticsWorkspace.outputs.logAnalyticsWsId
    serverOS: 'Linux'    
  }
}

module functionApp '../_modules/compute/app-services/web-app.bicep' = [for i in range(0, functionCount): {
  name: my.takeSafe('functionApp-${padLeft(string(i), 2, '0')}-${deployment().name}', 64)
  scope: rgShared
  params: {
    name: my.takeSafe(my.getUniqueName(resourceIdentifiers.functionApp, workloadName, env, location, rgShared.id, i + 1), 60) // updated index
    location: location
    tags: tags
    diagnosticWorkspaceId: sharedLogAnalyticsWorkspace.outputs.logAnalyticsWsId
    hasPrivateLink: true
    kind: 'functionapp,linux'
    serverFarmResourceId: asp.outputs.resourceId
    siteConfigSelection: 'linuxJava17Se'   
    virtualNetworkSubnetId: vnetSharedCreated::snetSharedIntegration.id
    systemAssignedIdentity: false
    userAssignedIdentities:  {
      '${functionUserAssignedManagedIdenity[i].outputs.id}': {}
    } 
    appInsightId: applicationInsights.outputs.id
  }
}]

module functionAppPrivateDnsZone '../_modules/networking/private-dns-zone.bicep' = if (empty(functionAppPrivateDnsZoneId)) {
  name: my.takeSafe('functionAppPrivateDnsZone-${deployment().name}', 64) 
  scope: rgShared
  params: {
    name: dnsZoneConsts.functions.dnsZoneName 
    vnetIdsToLink: [vnetShared.outputs.vnetId]
    tags: tags 
  }
}


module functionAppPrivateEndpoint '../_modules/networking/private-endpoint.bicep' = [for i in range(0, functionCount): {
  name: my.takeSafe('functionAppPrivateEndpoint-${padLeft(string(i+1), 2, '0')}-${deployment().name}', 64) 
  scope: rgShared
  params: {
    name: '${resourceIdentifiers.privateEndpoint}-${functionApp[i].outputs.name}' 
    location: location
    tags: tags
    privateDnsZonesId: empty(functionAppPrivateDnsZoneId) ? functionAppPrivateDnsZone.outputs.privateDnsZonesId : functionAppPrivateDnsZoneId 
    privateLinkServiceId: functionApp[i].outputs.resourceId 
    snetId: vnetSharedCreated::snetSharedPep.id
    subresource: dnsZoneConsts.functions.subResource
  }
}]


//----------------- VM Jumpbox --------------------

module vmWindows '../_modules/compute/jumphost-win11.bicep' = {
  name: my.takeSafe('vmWindows-${deployment().name}', 64)
  scope: rgShared
  params: {
    name: 'vm-shared-jumpbox'
    location: location
    tags: tags
    vmSize: envConfigMap[env].jumpbox.vmSize    
    adminUsername: envConfigMap[env].jumpbox.adminUsername
    adminPassword: envConfigMap[env].jumpbox.adminPassword
    subnetId: vnetSharedCreated::snetSharedDevOps.id
    enableAzureAdJoin: true
  }
  dependsOn: [
    // this is required to ensure the VM is created after the VNet
    vnetShared
  ]
}

// ------------------
// OUTPUTS
// ------------------
@description('Resource name of the newly created APIM')
output apimName string = apim.outputs.apimName

@description('Resource id of the newly created APIM')
output apimId string = apim.outputs.apimId

@description('Resource id of the VNet associated with the Shared resources')
output vnetSharedResourceId string = vnetShared.outputs.vnetId

@description('Name of the VNet associated with the Shared resources')
output vnetSharedName string = vnetShared.outputs.vnetName


@description('The id of the Keyvault')
output keyvaultId string = keyVault.outputs.keyvaultId

@description('The name of the Keyvault')
output keyvaultName string = keyVault.outputs.keyvaultName

@description('The id of the Private DNS Zone associated with the Keyvault')
output keyvaultPrivateDnsZoneId string =  empty(keyvaultPrivateDnsZoneId) ? keyvaultPrivateDnsZone.outputs.privateDnsZonesId : keyvaultPrivateDnsZoneId

@description('The id of the Private DNS Zone associated with the Function Apps')
output functionAppPrivateDnsZoneId string = empty(functionAppPrivateDnsZoneId) ?  functionAppPrivateDnsZone.outputs.privateDnsZonesId : functionAppPrivateDnsZoneId

@description('The id of the Private DNS Zone associated with the CosmosDB')
output cosmosDbPrivateDnsZoneId string = empty(cosmosDbPrivateDnsZoneId) ?  cosmosDbPrivateDnsZone.outputs.privateDnsZonesId : cosmosDbPrivateDnsZoneId
