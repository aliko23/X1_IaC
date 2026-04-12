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

@description('Configuration settings for the Spoke VNet')
param vnetSpokeConfiguration my.vnetSettingsType

@description('The Resource ID of the Hub VNet')
param vnetHubResourceId string

@description('The Resource ID of the centralized keyvault Private DNS Zone. If not provided, the module will create a new one.')
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

@description('The ConfigSet values for the Hub')
var envConfigMap = loadJsonContent('../_configuration/env_config_set.jsonc')

// naming of the resources
var vnetSpokeName = my.takeSafe(my.getName(resourceIdentifiers.virtualNetwork, workloadName, env, location, 1), 64)
var rgScopeName = my.takeSafe(my.getName(resourceIdentifiers.resourceGroup, workloadName, env, location, 1), 90)
var kvName = my.takeSafe(my.getUniqueName(resourceIdentifiers.keyVault, workloadName, env, location, rgScope.id, 1), 24)
var peKvName = '${resourceIdentifiers.privateEndpoint}-${kvName}'
var spokeLogWsName = my.takeSafe(my.getName(resourceIdentifiers.logAnalyticsWorkspace, workloadName, env, location, 1), 63)
var staticWebAppName = my.takeSafe(my.getName(resourceIdentifiers.staticwebapp, workloadName, env, location, 1), 40)
var peStaticWebAppName = '${resourceIdentifiers.privateEndpoint}-${staticWebAppName}'
var cosmosDbName = my.takeSafe(my.getUniqueName(resourceIdentifiers.cosmosDbNoSql, workloadName, env, location, rgScope.id, 1), 44)
var peCosmosDbName = '${resourceIdentifiers.privateEndpoint}-${cosmosDbName}'
var searchAiName = my.takeSafe(my.getUniqueName(resourceIdentifiers.searchService, workloadName, env, location, rgScope.id, 1), 60)
var peSearchAiName = '${resourceIdentifiers.privateEndpoint}-${searchAiName}'
var serviceBusName = my.takeSafe(my.getUniqueName(resourceIdentifiers.serviceBus, workloadName, env, location, rgScope.id, 1), 50)
var peServiceBusName = '${resourceIdentifiers.privateEndpoint}-${serviceBusName}'
var aspName = my.takeSafe(my.getName(resourceIdentifiers.appServicePlan, workloadName, env, location, 1), 40)
var functionCount = 3
var appInsightsName = my.takeSafe(my.getName(resourceIdentifiers.applicationInsights, workloadName, env, location, 1), 64)



// ------------------
// RESOURCES
// ------------------

@description('Creates the resource group for the VNet resources')
resource rgScope 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: rgScopeName
  location: location
  tags: tags  
}

@description('The log sink for Azure Diagnostics')
module spokeLogAnalyticsWorkspace '../_modules/monitoring/log-analytics-ws.bicep' = {
  scope: rgScope
  name: my.takeSafe('spokeLogWs-${uniqueString(rgScope.id)}', 64)
  params: {
    location: location
#disable-next-line BCP334
    name: spokeLogWsName
  }
}

@description('Azure Application Insights, the workload\' log & metric sink and APM tool')
module applicationInsights '../_modules/monitoring/app-insights.bicep' ={
  name: my.takeSafe('applicationInsights-${uniqueString(rgScope.id)}', 64)
  scope: rgScope
  params: {
    name: appInsightsName
    location: location
    tags: tags
    workspaceResourceId: spokeLogAnalyticsWorkspace.outputs.logAnalyticsWsId
  }
}


@description('Creates the VNet for the APIM')
module vnetSpoke '../_modules/networking/vnet.bicep' = {
  scope: rgScope
  name: my.takeSafe('vnetSpoke-${deployment().name}', 64)
  params: {
    name: vnetSpokeName
    vnetAddressPrefixes: [vnetSpokeConfiguration.addressSpace]
    subnets: [ 
      for subnet in vnetSpokeConfiguration.subnets: {
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

@description('NSG Rules for the Integration subnet.')
module nsgIntegration '../_modules/networking/nsg.bicep' = {
  name: my.takeSafe('nsgIntegration-${deployment().name}', 64)
  scope: rgScope
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
  scope: rgScope
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
  scope: rgScope
  params: {
    name: 'nsg-pep'
    location: location
    tags: tags
    securityRules: []
  }
}

@description('Gets a reference to the newly created VNet and its subnets')
resource vnetSpokeCreated 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetSpokeName
  scope: rgScope

  resource snetSpokeIntegration 'subnets' existing = {
    name: vnetSpokeConfiguration.subnets[0].name
  }

  resource snetSpokePep 'subnets' existing =  {
    name: vnetSpokeConfiguration.subnets[1].name
  }
  
  resource snetSpokeDevOps 'subnets' existing = {
    name: vnetSpokeConfiguration.subnets[2].name
  }
}


//----------------- Keyvault section --------------------

@description('Create a KeyVault with a private endpoint in the VNet')
module keyVault '../_modules/security/keyvault.bicep' = {
  name: my.takeSafe('keyvault-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: kvName
    location: location
    enableRbacAuthorization: true
    hasPrivateEndpoint: true
    tags: tags       
    diagnosticWorkspaceId: spokeLogAnalyticsWorkspace.outputs.logAnalyticsWsId
  }
}

module keyvaultPrivateDnsZone '../_modules/networking/private-dns-zone.bicep' = if (empty(keyvaultPrivateDnsZoneId)) {
  name: my.takeSafe('keyvaultPrivateDnsZone-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: dnsZoneConsts.keyvault.dnsZoneName
    vnetIdsToLink: empty(vnetHubResourceId) ? [vnetSpoke.outputs.vnetId
      ] : [vnetSpoke.outputs.vnetId, vnetHubResourceId]
    tags: tags // added tags parameter
  }
}


module keyvaultPrivateEndpoint '../_modules/networking/private-endpoint.bicep' = {
  name: my.takeSafe('keyvaultPrivateEndpoint-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: peKvName
    location: location
    tags: tags
    privateDnsZonesId: empty(keyvaultPrivateDnsZoneId) ? keyvaultPrivateDnsZone.outputs.privateDnsZonesId : keyvaultPrivateDnsZoneId
    privateLinkServiceId: keyVault.outputs.keyvaultId
    snetId: vnetSpokeCreated::snetSpokePep.id
    subresource: dnsZoneConsts.keyvault.subResource    
  }  
}

//----------------- Static web App section --------------------
@description('Creates a Static Web App')
module staticWebApp '../_modules/compute/static-web-app.bicep' = {
  name: my.takeSafe('staticWebApp-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: staticWebAppName
    //static site is actually a global resource, so location is not needed
    sku: envConfigMap[env].staticWebApp.sku
    hasPrivateEndpoint: true
  }
}

module staticWebAppPrivateDnsZone '../_modules/networking/private-dns-zone.bicep' = {
  name: my.takeSafe('staticWebAppPrivateDnsZone-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: dnsZoneConsts.staticwebsite.dnsZoneName
    vnetIdsToLink: empty(vnetHubResourceId) ? [vnetSpoke.outputs.vnetId
      ] : [vnetSpoke.outputs.vnetId, vnetHubResourceId]
    tags: tags // added tags parameter
  }
}

module staticWebAppPrivateEndpoint '../_modules/networking/private-endpoint.bicep' = {
  name: my.takeSafe('staticWebAppPrivateEndpoint-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: peStaticWebAppName
    location: location
    tags: tags
    privateDnsZonesId: staticWebAppPrivateDnsZone.outputs.privateDnsZonesId
    privateLinkServiceId: staticWebApp.outputs.resourceId
    snetId: vnetSpokeCreated::snetSpokePep.id
    subresource: dnsZoneConsts.staticwebsite.subResource    
  }
}

//----------------- CosmosDB section --------------------
@description('Creates a CosmosDB account with a private endpoint in the VNet')
module cosmosDb '../_modules/storage/cosmos-db-no-sql.bicep' = {
  name: my.takeSafe('cosmosDb-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: cosmosDbName
    location: location
    tags: tags
    hasPrivateEndpoint: true
    locations: envConfigMap[env].cosmosDb.accountProperties.locations
    automaticFailover: envConfigMap[env].cosmosDb.accountProperties.enableAutomaticFailover
    containers: envConfigMap[env].cosmosDb.containers   
    diagnosticWorkspaceId: spokeLogAnalyticsWorkspace.outputs.logAnalyticsWsId
  }
}

module cosmosDbPrivateDnsZone '../_modules/networking/private-dns-zone.bicep' = if (empty(cosmosDbPrivateDnsZoneId)) {
  name: my.takeSafe('cosmosDbPrivateDnsZone-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: dnsZoneConsts.cosmosdb.dnsZoneName
    vnetIdsToLink: empty(vnetHubResourceId) ? [vnetSpoke.outputs.vnetId
      ] : [vnetSpoke.outputs.vnetId, vnetHubResourceId]
    tags: tags // added tags parameter
  }
}

module cosmosDbPrivateEndpoint '../_modules/networking/private-endpoint.bicep' = {
  name: my.takeSafe('cosmosDbPrivateEndpoint-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: peCosmosDbName
    location: location
    tags: tags
    privateDnsZonesId: empty(cosmosDbPrivateDnsZoneId) ? cosmosDbPrivateDnsZone.outputs.privateDnsZonesId : cosmosDbPrivateDnsZoneId
    privateLinkServiceId: cosmosDb.outputs.resourceId
    snetId: vnetSpokeCreated::snetSpokePep.id
    subresource: dnsZoneConsts.cosmosdb.subResource  
  }
}

//----------------- Function Apps section --------------------


@description('The managed identities for the function apps')
module functionUserAssignedManagedIdenity '../_modules/identity/userAssignedManagedIdentity.bicep' =  [for i in range(0, functionCount): {
  name: my.takeSafe('funcUserAssignedManagedIdenity-${padLeft(string(i), 2, '0')}-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: '${resourceIdentifiers.managedIdentity}-${my.takeSafe(my.getUniqueName(resourceIdentifiers.functionApp, workloadName, env, location, rgScope.id, i + 1), 60)}' // updated rgShared to rgScope
    location: location
    tags: tags
  }
}]


@description('The function app service plan')
module asp '../_modules/compute/app-services/app-service-plan.bicep' = {
  name: my.takeSafe('functionsElasticPlan-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: aspName
    location: location
    sku: envConfigMap[env].functionApp.sku    
    tags: tags
    diagnosticWorkspaceId: spokeLogAnalyticsWorkspace.outputs.logAnalyticsWsId
    serverOS: 'Linux'    
  }
}


@description('Creates n Function Apps with a private endpoint in the VNet')
module functionApp '../_modules/compute/app-services/web-app.bicep' = [for i in range(0, functionCount): {
  name: my.takeSafe('functionApp-${padLeft(string(i), 2, '0')}-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: my.takeSafe(my.getUniqueName(resourceIdentifiers.functionApp, workloadName, env, location, rgScope.id, i + 1), 60) // updated index
    location: location
    tags: tags
    diagnosticWorkspaceId: spokeLogAnalyticsWorkspace.outputs.logAnalyticsWsId
    hasPrivateLink: true
    kind: 'functionapp,linux'
    serverFarmResourceId: asp.outputs.resourceId
    siteConfigSelection: 'linuxJava17Se'   
    virtualNetworkSubnetId: vnetSpokeCreated::snetSpokeIntegration.id
    systemAssignedIdentity: false
    userAssignedIdentities:  {
      '${functionUserAssignedManagedIdenity[i].outputs.id}': {}
    } 
    appInsightId: applicationInsights.outputs.id
  }
}]


module functionAppPrivateDnsZone '../_modules/networking/private-dns-zone.bicep' = if (empty(functionAppPrivateDnsZoneId)) {
  name: my.takeSafe('functionAppPrivateDnsZone-${deployment().name}', 64) // updated name parameter
  scope: rgScope
  params: {
    name: dnsZoneConsts.functions.dnsZoneName // updated name parameter for function app
    vnetIdsToLink: empty(vnetHubResourceId) ? [vnetSpoke.outputs.vnetId
      ] : [vnetSpoke.outputs.vnetId, vnetHubResourceId]
    tags: tags // added tags parameter
  }
}

module functionAppPrivateEndpoint '../_modules/networking/private-endpoint.bicep' = [for i in range(0, functionCount): {
  name: my.takeSafe('functionAppPrivateEndpoint-${padLeft(string(i+1), 2, '0')}-${deployment().name}', 64) // updated name parameter
  scope: rgScope
  params: {
    name: '${resourceIdentifiers.privateEndpoint}-${functionApp[i].outputs.name}' // updated name parameter for function app
    location: location
    tags: tags
    privateDnsZonesId: empty(functionAppPrivateDnsZoneId) ? functionAppPrivateDnsZone.outputs.privateDnsZonesId : functionAppPrivateDnsZoneId// updated reference
    privateLinkServiceId: functionApp[i].outputs.resourceId // updated reference
    snetId: vnetSpokeCreated::snetSpokePep.id
    subresource: dnsZoneConsts.functions.subResource // updated subresource reference
  }
}]

//----------------- Service Bus section --------------------
module serviceBus '../_modules/storage/service-bus.bicep' = {
  name: my.takeSafe('serviceBus-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: serviceBusName
    location: location
    tags: tags
    skuName: envConfigMap[env].serviceBus.namespace.sku 
    capacity: envConfigMap[env].serviceBus.namespace.capacity
    publicNetworkAccess: envConfigMap[env].serviceBus.namespace.sku == 'Premium' ? 'Disabled' : 'Enabled'
    diagnosticWorkspaceId: spokeLogAnalyticsWorkspace.outputs.logAnalyticsWsId
    queues: envConfigMap[env].serviceBus.queues
  }
}

module serviceBusPrivateDnsZone '../_modules/networking/private-dns-zone.bicep' = if (envConfigMap[env].serviceBus.namespace.sku == 'Premium') {
  name: my.takeSafe('serviceBusPrivateDnsZone-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: dnsZoneConsts.serviceBus.dnsZoneName
    vnetIdsToLink: empty(vnetHubResourceId) ? [vnetSpoke.outputs.vnetId
      ] : [vnetSpoke.outputs.vnetId, vnetHubResourceId]
    tags: tags // added tags parameter
  }
}

module serviceBusPrivateEndpoint '../_modules/networking/private-endpoint.bicep' = if (envConfigMap[env].serviceBus.namespace.sku == 'Premium'){
  name: my.takeSafe('serviceBusPrivateEndpoint-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: peServiceBusName // updated name parameter
    location: location
    tags: tags
    privateDnsZonesId: envConfigMap[env].serviceBus.namespace.sku == 'Premium' ? serviceBusPrivateDnsZone.outputs.privateDnsZonesId : ''
    privateLinkServiceId: serviceBus.outputs.id // updated reference
    snetId: vnetSpokeCreated::snetSpokePep.id
    subresource: dnsZoneConsts.serviceBus.subResource // updated subresource reference
  }
}




//----------------- Search AI section --------------------
module searchAi '../_modules/ai/search-ai.bicep' = {
  name: my.takeSafe('searchAi-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: searchAiName
    location: location
    tags: tags
    sku: envConfigMap[env].searchAi.sku
    publicNetworkAccess:  'disabled'
    diagnosticWorkspaceId: spokeLogAnalyticsWorkspace.outputs.logAnalyticsWsId
  }
}

module searchAiPrivateDnsZone '../_modules/networking/private-dns-zone.bicep' = {
  name: my.takeSafe('searchAiPrivateDnsZone-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: dnsZoneConsts.searchAi.dnsZoneName
    vnetIdsToLink: empty(vnetHubResourceId) ? [vnetSpoke.outputs.vnetId
      ] : [vnetSpoke.outputs.vnetId, vnetHubResourceId]
    tags: tags // added tags parameter
  }
}

module searchAiPrivateEndpoint '../_modules/networking/private-endpoint.bicep' = {
  name: my.takeSafe('searchAiPrivateEndpoint-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: peSearchAiName
    location: location
    tags: tags
    privateDnsZonesId: searchAiPrivateDnsZone.outputs.privateDnsZonesId
    privateLinkServiceId: searchAi.outputs.id
    snetId: vnetSpokeCreated::snetSpokePep.id
    subresource: dnsZoneConsts.searchAi.subResource    
  }
}


//----------------- VM Jumpbox --------------------
module vmWindows '../_modules/compute/jumphost-win11.bicep' = {
  name: my.takeSafe('vmWindows-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: 'vm-jumpbox'
    location: location
    tags: tags
    vmSize: envConfigMap[env].jumpbox.vmSize    
    adminUsername: envConfigMap[env].jumpbox.adminUsername
    adminPassword: envConfigMap[env].jumpbox.adminPassword
    subnetId: vnetSpokeCreated::snetSpokeDevOps.id
    enableAzureAdJoin: true
  }
  dependsOn: [
    // this is required to ensure the VM is created after the VNet
    vnetSpoke
  ]
}


// ------------------
// OUTPUTS
// ------------------

@description('The id of the Keyvault')
output keyvaultId string = keyVault.outputs.keyvaultId

@description('The name of the Keyvault')
output keyvaultName string = keyVault.outputs.keyvaultName

@description('The id of the staticWebApp')
output staticWebAppId string = staticWebApp.outputs.resourceId

@description('The name of the staticWebApp')
output staticWebAppName string = staticWebApp.outputs.name

@description('The default autogenerated hostname for the static site.')
output staticWebAppDefaultHostname string = staticWebApp.outputs.defaultHostname
