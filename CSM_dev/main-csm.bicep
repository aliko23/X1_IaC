targetScope = 'subscription'

// ------------------
//    IMPORTS
// ------------------
import * as my from './_modules/exports.bicep'

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

@description('exsisting RG name')
param rgName string

//@description('exsisting LAW name')
//param lawName string

//@description('exsisting LAW RG')
//param rgLawName string

@description('exsisting Vnet name')
param  vnetConfiguration object


// ------------------
// VARIABLES
// ------------------

var tags = {
  environment: env
}

@description('The regions, used in the naming scheme')
var resourceIdentifiers = loadJsonContent('./_configuration/resourceTypeAbbreviations.json')

@description('The ConfigSet values for the Hub')
var envConfigMap = loadJsonContent('./_configuration/env_config_set.jsonc')
var aspName = my.takeSafe(my.getName(resourceIdentifiers.appServicePlan, workloadName, env, location, 1), 40)
var functionCount = 1
//var appInsightsName = my.takeSafe(my.getName(resourceIdentifiers.applicationInsights, workloadName, env, location, 1), 64)

// ------------------
// RESOURCES
// ------------------

@description('Creates the resource group for the VNet resources')
resource rgScope 'Microsoft.Resources/resourceGroups@2024-07-01' existing = {
  name: rgName
}

//@description('The log sink for Azure Diagnostics')
//resource laws 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing= {
//  name: lawName
//  scope: resourceGroup(rgLawName)
//}

@description('Gets a reference to the newly created VNet and its subnets')
resource vnetSpokeCreated 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetConfiguration.vnetName
  scope: rgScope

  resource snetSpokeIntegration 'subnets' existing = {
    name: vnetConfiguration.subnets[0].name
  }
}


//----------------- App Insights section --------------------

//@description('Azure Application Insights, the workload\' log & metric sink and APM tool')
//module applicationInsights './_modules/monitoring/app-insights.bicep' ={
//  name: my.takeSafe('applicationInsights-${uniqueString(rgScope.id)}', 64)
//  scope: rgScope
//  params: {
//    name: appInsightsName
//    location: location
//    tags: tags
//    workspaceResourceId: laws.id
//  }
//}

//----------------- Azure Service Plan section --------------------

@description('The function app service plan')
module asp './_modules/compute/app-services/app-service-plan.bicep' = {
  name: my.takeSafe('functionsElasticPlan-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: aspName
    location: location
    sku: envConfigMap[env].functionApp.sku    
    tags: tags
    //diagnosticWorkspaceId: laws.id
    serverOS: 'Linux'    
  }
}

//----------------- Function Apps section --------------------

@description('Creates n Function Apps with a private endpoint in the VNet')
module functionApp './_modules/compute/app-services/web-app.bicep' = [for i in range(0, functionCount): {
  name: my.takeSafe('functionApp-${padLeft(string(i), 2, '0')}-${deployment().name}', 64)
  scope: rgScope
  params: {
    name: my.takeSafe(my.getUniqueName(resourceIdentifiers.functionApp, workloadName, env, location, rgScope.id, i + 1), 60) // updated index
    location: location
    tags: tags
    //diagnosticWorkspaceId: laws.id
    hasPrivateLink: false
    kind: 'functionapp,linux'
    serverFarmResourceId: asp.outputs.resourceId
    siteConfigSelection: 'linuxJava17Se'   
    virtualNetworkSubnetId: vnetSpokeCreated::snetSpokeIntegration.id
    systemAssignedIdentity: true
    //appInsightId: applicationInsights.outputs.id
  }
}]


  








