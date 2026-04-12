metadata name = 'DocumentDB Database Accounts'
metadata description = 'This module deploys a DocumentDB Database Account.'

@description('Required. Name of the Cosmos Database Resource.')
param name string

@description('The name of the Cosmos NoSQL Database.')
param sqlDbName string = 'cosmos-${name}'

@description('Optional. Default to current resource group scope location. Location for all resources.')
param location string = resourceGroup().location

@description('The failover locations of the Cosmos Database Account. The first location is the primary location. The rest are secondary locations. The primary location is the first location in the list. The failover priority of the primary location is 0. The failover priority of the secondary locations is 1, 2, 3, ...')
param locations object[] = []

@description('Optional. Tags of the Database Account resource.')
param tags object?


@description('Optional. Default to Standard. The offer type for the Azure Cosmos DB database account.')
@allowed([
  'Standard'
])
param databaseAccountOfferType string = 'Standard'


@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
@description('Optional. Default to Session. The default consistency level of the Cosmos DB account.')
param defaultConsistencyLevel string = 'Session'

@description('Optional. Default to true. Opt-out of local authentication and ensure only MSI and AAD can be used exclusively for authentication.')
param disableLocalAuth bool = true

@description('Optional. Default to false. Flag to indicate whether to enable storage analytics.')
param enableAnalyticalStorage bool = false

@description('Optional. Default to true. Enable automatic failover for regions.')
param automaticFailover bool = true

@description('Optional. Default to false. Flag to indicate whether Free Tier is enabled.')
param enableFreeTier bool = false

@description('Optional. Default to false. Enables the account to write in multiple locations. Periodic backup must be used if enabled.')
param enableMultipleWriteLocations bool = false

@description('Optional. Default to true. Disable write operations on metadata resources (databases, containers, throughput) via account keys.')
param disableKeyBasedMetadataWriteAccess bool = true

@minValue(1)
@maxValue(2147483647)
@description('Optional. Default to 100000. Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 1000000. Multi Region: 100000 to 1000000.')
param maxStalenessPrefix int = 100000

@minValue(5)
@maxValue(86400)
@description('Optional. Default to 300. Max lag time (minutes). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
param maxIntervalInSeconds int = 300


@description('Optional. Default to unlimited. The total throughput limit imposed on this Cosmos DB account (RU/s).')
param totalThroughputLimit int = -1


@allowed([
  'EnableCassandra'
  'EnableTable'
  'EnableGremlin'
  'EnableMongo'
  'DisableRateLimitingResponses'
  'EnableServerless'
  'EnableNoSQLVectorSearch'
  'EnableNoSQLFullTextSearch'
  'EnableMaterializedViews'
  'DeleteAllItemsByPartitionKey'
])
@description('Optional. List of Cosmos DB capabilities for the account. THE DeleteAllItemsByPartitionKey VALUE USED IN THIS PARAMETER IS USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION.')
param capabilitiesToAdd string[] = []

@allowed([
  'Periodic'
  'Continuous'
])
@description('Optional. Default to Continuous. Describes the mode of backups. Periodic backup must be used if multiple write locations are used.')
param backupPolicyType string = 'Continuous'

@allowed([
  'Continuous30Days'
  'Continuous7Days'
])
@description('Optional. Default to Continuous30Days. Configuration values for continuous mode backup.')
param backupPolicyContinuousTier string = 'Continuous30Days'

@minValue(60)
@maxValue(1440)
@description('Optional. Default to 240. An integer representing the interval in minutes between two backups. Only applies to periodic backup type.')
param backupIntervalInMinutes int = 240

@minValue(2)
@maxValue(720)
@description('Optional. Default to 8. An integer representing the time (in hours) that each backup is retained. Only applies to periodic backup type.')
param backupRetentionIntervalInHours int = 8

@allowed([
  'Geo'
  'Local'
  'Zone'
])
@description('Optional. Default to Local. Enum to indicate type of backup residency. Only applies to periodic backup type.')
param backupStorageRedundancy string = 'Local'


@allowed([
  'Tls12'
])
@description('Optional. Default to TLS 1.2. Enum to indicate the minimum allowed TLS version. Azure Cosmos DB for MongoDB RU and Apache Cassandra only work with TLS 1.2 or later.')
param minimumTlsVersion string = 'Tls12'

@description('Optional. Request units per second. Will be ignored if autoscaleSettingsMaxThroughput is used. Setting throughput at the database level is only recommended for development/test or when workload across all containers in the shared throughput database is uniform. For best performance for large production workloads, it is recommended to set dedicated throughput (autoscale or manual) at the container level and not at the database level.')
param throughput int?

@description('Optional. Specifies the Autoscale settings and represents maximum throughput, the resource can scale up to. The autoscale throughput should have valid throughput values between 1000 and 1000000 inclusive in increments of 1000. If value is set to null, then autoscale will be disabled. Setting throughput at the database level is only recommended for development/test or when workload across all containers in the shared throughput database is uniform. For best performance for large production workloads, it is recommended to set dedicated throughput (autoscale or manual) at the container level and not at the database level.')
param autoscaleSettingsMaxThroughput int?

@description('Optional. Array of containers to deploy in the SQL database.')
param containers object[] = []

@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional, default is true. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = true

@description('Conditional. The ID(s) to assign to the resource. Required if a user assigned identity is used for encryption.')
param userAssignedIdentities object = {}

@description('If the CosmosDB has private endpoints enabled.')
param hasPrivateEndpoint bool

@description('Optional. Whether or not public network access is allowed for this resource. For security reasons it should be disabled. If not specified, it will be disabled by default if private endpoints are set.')
@allowed([
  ''
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = ''

var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
} : null


var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}

var defaultFailoverLocation = [
  {
    failoverPriority: 0
    locationName: location
    isZoneRedundant: true
  }
]


var capabilities = [
  for capability in capabilitiesToAdd: {
    name: capability
  }
]

var backupPolicy = backupPolicyType == 'Continuous'
  ? {
      type: backupPolicyType
      continuousModeProperties: {
        tier: backupPolicyContinuousTier
      }
    }
  : {
      type: backupPolicyType
      periodicModeProperties: {
        backupIntervalInMinutes: backupIntervalInMinutes
        backupRetentionIntervalInHours: backupRetentionIntervalInHours
        backupStorageRedundancy: backupStorageRedundancy
      }
    }

#disable-next-line no-unused-vars
var builtInRoleNames = {
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  'Cosmos DB Account Reader Role': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'fbdf93bf-df7d-467e-a4d2-9458aa1360c8'
  )
  'Cosmos DB Operator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '230815da-be43-4aae-9cb4-875f7bd000aa'
  )
  CosmosBackupOperator: subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'db7b14f2-5adf-42da-9f96-f2ee17bab5cb'
  )
  CosmosRestoreOperator: subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '5432c526-bc82-444a-b7ba-57c5b0b5b34f'
  )
  'DocumentDB Account Contributor': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '5bd9cd88-fe45-4216-938b-f97437e15450'
  )
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Role Based Access Control Administrator (Preview)': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'f58310d9-a9f6-439a-9e8d-f62e7b41a168'
  )
  'User Access Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
  )
}



resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = {
  name: name
  location: location
  tags: tags
  identity: identity
  kind: 'GlobalDocumentDB'
  properties:  {
    databaseAccountOfferType: databaseAccountOfferType    
    #disable-next-line BCP225
    backupPolicy: backupPolicy
    capabilities: capabilities
    minimalTlsVersion: minimumTlsVersion
    capacity: {
      totalThroughputLimit: totalThroughputLimit
    }
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    enableMultipleWriteLocations: enableMultipleWriteLocations
    locations: empty(locations) ? defaultFailoverLocation : locations    
    publicNetworkAccess: !empty(publicNetworkAccess) ? any(publicNetworkAccess) : (hasPrivateEndpoint ? 'Disabled' : null)
    enableFreeTier: enableFreeTier
    enableAutomaticFailover: automaticFailover
    enableAnalyticalStorage: enableAnalyticalStorage  
    disableLocalAuth: disableLocalAuth
    disableKeyBasedMetadataWriteAccess: disableKeyBasedMetadataWriteAccess        
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' =if ( !empty(diagnosticWorkspaceId) )  {
  name: '${name}-diagnosticSettings'
  scope: databaseAccount
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

resource sqlDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-11-15' = {
  name: sqlDbName
  parent: databaseAccount
  tags: tags
  properties: {
    resource: {
      id: sqlDbName
    }
    options: contains(databaseAccount.properties.capabilities, { name: 'EnableServerless' })
      ? null
      : {
          throughput: autoscaleSettingsMaxThroughput == null ? throughput : null
          autoscaleSettings: autoscaleSettingsMaxThroughput != null
            ? {
                maxThroughput: autoscaleSettingsMaxThroughput
              }
            : null
        }
  }
}

module container 'cosmos-db-no-sql.container.bicep' = [
  for container in containers: {
    name: '${uniqueString(deployment().name, sqlDatabase.name)}-sqldb-${container.name}'
    params: {
      databaseAccountName: name
      sqlDatabaseName: sqlDbName
      name: container.name      
      autoscaleSettingsMaxThroughput: container.?autoscaleSettingsMaxThroughput 
      partitionKeyPath: container.?partitionKeyPath
      throughput: (throughput != null || autoscaleSettingsMaxThroughput != null) && container.?throughput == null
        ? -1
        : container.?throughput
    }
  }
]


@description('The name of the database account.')
output name string = databaseAccount.name

@description('The resource ID of the database account.')
output resourceId string = databaseAccount.id

@description('The name of the resource group the database account was created in.')
output resourceGroupName string = resourceGroup().name

@description('The principal ID of the system assigned identity.')
output systemAssignedMIPrincipalId string? = databaseAccount.?identity.?principalId

@description('The location the resource was deployed into.')
output location string = databaseAccount.location

@description('The endpoint of the database account.')
output endpoint string = databaseAccount.properties.documentEndpoint
