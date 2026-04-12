metadata description = 'Creates an Azure AI Search instance.'
param name string
param location string = resourceGroup().location
param tags object = {}

@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('The SKU of the search service.')
@allowed([
  'free'
  'basic'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
param sku string = 'basic'

@description('Optional. Defines the options for how the data plane API of a Search service authenticates requests. Must remain an empty object {} if \'disableLocalAuth\' is set to true.')
param authOptions object = {}

@description('Optional. When set to true, calls to the search service will not be permitted to utilize API keys for authentication. This cannot be set to true if \'authOptions\' are defined.')
param disableLocalAuth bool = false

param disabledDataExfiltrationOptions array = []

@description('Optional. Describes a policy that determines how resources within the search service are to be encrypted with Customer Managed Keys.')
@allowed([
  'Disabled'
  'Enabled'
  'Unspecified'
])
param encryptionWithCmk string = 'Unspecified'


@allowed([
  'default'
  'highDensity'
])
param hostingMode string = 'default'
param networkRuleSet object = {
  bypass: 'None'
  ipRules: []
}
param partitionCount int = 1
@allowed([
  'enabled'
  'disabled'
])
param publicNetworkAccess string = 'enabled'
param replicaCount int = 1
@allowed([
  'disabled'
  'free'
  'standard'
])
param semanticSearch string = 'disabled'


var searchIdentityProvider = (sku == 'free') ? null : {
  type: 'SystemAssigned'
}

resource search 'Microsoft.Search/searchServices@2021-04-01-preview' = {
  name: name
  location: location
  tags: tags
  // The free tier does not support managed identity
  identity: searchIdentityProvider
  properties: {
    authOptions: disableLocalAuth ? null : authOptions
    disableLocalAuth: disableLocalAuth
    disabledDataExfiltrationOptions: disabledDataExfiltrationOptions
    encryptionWithCmk: {
      enforcement: encryptionWithCmk
    }
    hostingMode: hostingMode
    networkRuleSet: networkRuleSet
    partitionCount: partitionCount
    publicNetworkAccess: publicNetworkAccess
    replicaCount: replicaCount
    semanticSearch: semanticSearch
  }
  sku: {
    name: sku
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' =if ( !empty(diagnosticWorkspaceId) )  {
  name: '${name}-diagnosticSettings'
  scope: search
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


output id string = search.id
output endpoint string = 'https://${name}.search.windows.net/'
output name string = search.name
output principalId string = !empty(searchIdentityProvider) ? search.identity.principalId : ''
