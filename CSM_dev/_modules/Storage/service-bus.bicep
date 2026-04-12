// Parameters
@description('Specifies the name of the Service Bus namespace.')
param name string

@description('Enabling this property creates a Premium Service Bus Namespace in regions supported availability zones.')
param zoneRedundant bool = true

@description('Specifies the name of Service Bus namespace SKU.')
@allowed([
  'Basic'
  'Premium'
  'Standard'
])
param skuName string = 'Standard'

@description('Specifies the messaging units for the Service Bus namespace. For Premium tier, capacity are 1,2 and 4.')
param capacity int = 1

@description('Specifies the name of the Service Bus queue.')
param queues array = []

@description('Specifies the name of the Service Bus topic.')
param topicNames array = []

@description('Specifies whether duplication is enabled on the queue.')
param requiresDuplicateDetection bool = false

@description('Specifies whether dead lettering is enabled on the queue.')
param deadLetteringOnMessageExpiration bool = false

@description('Specifies the duplicate detection history time of the queue.')
param duplicateDetectionHistoryTimeWindow string = 'PT10M'

@description('Specifies the resource id of the Log Analytics workspace.')
param diagnosticWorkspaceId string


@description('Specifies whether the namespace is accessible from internet.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Specifies the location.')
param location string = resourceGroup().location

@description('Specifies the resource tags.')
param tags object



var serviceBusEndpoint = '${namespace.id}/AuthorizationRules/RootManageSharedAccessKey'
var serviceBusConnectionString = listKeys(serviceBusEndpoint, namespace.apiVersion).primaryConnectionString

// Resources
resource namespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: capacity
  }
  properties: {
    zoneRedundant: skuName == 'Premium' ? zoneRedundant : false
    disableLocalAuth: publicNetworkAccess == 'Disabled' ? false : true
    publicNetworkAccess: publicNetworkAccess
  }
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = [for queue in queues: {
  parent: namespace
  name: queue.name
  properties: {
    lockDuration: queue.lockDuration
    maxSizeInMegabytes: queue.maxSizeInMegabytes
    requiresDuplicateDetection: queue.requiresDuplicateDetection
    requiresSession: queue.requiresSession
    deadLetteringOnMessageExpiration: deadLetteringOnMessageExpiration
    duplicateDetectionHistoryTimeWindow: duplicateDetectionHistoryTimeWindow
    maxDeliveryCount: queue.maxDeliveryCount
    defaultMessageTimeToLive: queue.defaultMessageTimeToLive
  }
}]

resource topic 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = [for topicName in topicNames: {
  parent: namespace
  name: topicName
  properties: {
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: requiresDuplicateDetection
    duplicateDetectionHistoryTimeWindow: duplicateDetectionHistoryTimeWindow
    enableBatchedOperations: true
    enablePartitioning: true
  }
}]

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${name}-diagnosticSettings'
  scope: namespace
  properties: {
    workspaceId: diagnosticWorkspaceId
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
  }
}

// Outputs
output id string = namespace.id
output name string = namespace.name
output connectionString string = serviceBusConnectionString
output queues array = [for (q, i) in queues: {
  name: q.name
  id: queue[i].id
}]
output topics array = [for (topicName, i) in topicNames: {
  name: name
  id: topic[i].id
}]
