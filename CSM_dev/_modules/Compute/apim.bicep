// ------------------
//    PARAMETERS
// ------------------


@description('Required. The name of the API management resource.')
param name string

@description('The tags to be attached to the module resources')
param tags object

@description('The location of the resources')
param location string

@description('The subnet resource id to use for APIM.')
@minLength(1)
param apimSubnetId string

@description('The email address of the publisher of the APIM resource.')
@minLength(1)
param publisherEmail string 

@description('Company name of the publisher of the APIM resource.')
@minLength(1)
param publisherName string 

@description('The pricing tier of the APIM resource.')
param skuName string 

@description('The instance size of the APIM resource.')
param capacity int

@description('The type of the APIM resource.')
@allowed([
  'None'
  'External'
  'Internal'
])
param virtualNetworkType string 

@description('The pip resource ID of the APIM resource.')
param publicIpAddressId string

@description('The id of the application Insights.')
param appInsightsId string = ''

@description('The instrumentation key of the application Insights.')
param appInsightsInstrumentationKey string = ''


@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''




// ------------------
// RESOURCES
// ------------------

@description('Creates the APIM')
resource apim 'Microsoft.ApiManagement/service@2024-05-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName 
    capacity: capacity 
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    publicIpAddressId: publicIpAddressId
    virtualNetworkType: virtualNetworkType
    virtualNetworkConfiguration: {
      subnetResourceId: apimSubnetId
    }
  }   
  identity: {
    type: 'SystemAssigned'
  }
}



resource apimAppInsightsIntegration 'Microsoft.ApiManagement/service/loggers@2024-05-01' = if ( !empty(appInsightsId) )  {
  parent: apim
  name: 'logger-appinsights-${name}'
  properties: {
    loggerType: 'applicationInsights'
    resourceId: appInsightsId
    credentials: {
      instrumentationKey: appInsightsInstrumentationKey
    }    
  }
}

// resource apimDiagnosticsIntegration 'Microsoft.ApiManagement/service/diagnostics@2024-05-01' = if ( !empty(appInsightsId) ) {
//   parent: apim
//   name: 'apim-diagnostics-99'
//   properties: {
//     loggerId: apimAppInsightsIntegration.id
//     alwaysLog: 'allErrors'
//     sampling: {
//       percentage: 100
//       samplingType: 'fixed'
//     }
//     metrics: true    
//   }
// }

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' =if ( !empty(diagnosticWorkspaceId) )  {
  name: '${name}-diagnosticSettings'
  scope: apim
  properties: {
    logs: [    
      {        
        enabled: true
        categoryGroup: 'allLogs'      
      }
    ]
    metrics: [
      {
        enabled: true        
        category: 'AllMetrics'
      }
    ]
    workspaceId: diagnosticWorkspaceId
  }
}


// ------------------
// OUTPUTS
// ------------------

@description('Resource name of the newly created APIM')
output apimName string = apim.name

@description('Resource id of the newly created APIM')
output apimId string = apim.id
