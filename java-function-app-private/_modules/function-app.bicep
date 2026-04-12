// Java Function App module with vnet integration

@description('Location for the Function App')
param location string

@description('Name of the Function App')
param functionAppName string

@description('App Service Plan ID')
param appServicePlanId string

@description('Storage Account connection string')
param storageAccountConnectionString string

@description('Subnet ID for vnet integration')
param vnetSubnetId string

@description('Java version for the Function App')
@allowed([
  '8'
  '11'
  '17'
  '21'
])
param javaVersion string = '17'

@description('Runtime stack')
param runtimeStack string = 'JAVA|${javaVersion}'

@description('Whether to enable HTTPS only')
param httpsOnly bool = true

@description('Resource tags')
param tags object

// Create Function App
resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: httpsOnly
    virtualNetworkSubnetId: vnetSubnetId
    siteConfig: {
      linuxFxVersion: runtimeStack
      alwaysOn: true
      functionAppScaleLimit: 10
      minimumElasticInstanceCount: 1
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageAccountConnectionString
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageAccountConnectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'java'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '0'
        }
        {
          name: 'WEBSITE_ENABLE_SYNC_UPDATE_SITE'
          value: 'true'
        }
        {
          name: 'WEBSITE_TIME_ZONE'
          value: 'UTC'
        }
      ]
    }
  }
  tags: tags
}

// Configure web configuration
resource webConfig 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: functionApp
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: []
    netFrameworkVersion: 'v4.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    detailedErrorLoggingEnabled: false
    publishingUsername: '@${functionApp.name}'
    scmType: 'None'
    use32BitWorkerProcess: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: true
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 0
    functionAppScaleLimit: 10
    fileChangeAuditEnabled: false
    functionsRuntimeScaleMonitoringEnabled: false
    websiteTimeZone: 'UTC'
    minimumElasticInstanceCount: 1
  }
}

// Output Function App details
output functionAppId string = functionApp.id
output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}/'
output functionAppPrincipalId string = functionApp.identity.principalId
