// Data Collection Rule Module
// Creates a Data Collection Rule for Azure Monitor agent configuration

param location string
param dcrName string
param workspaceResourceId string
param tags object = {}

// Collection rule configuration
param description string = 'Data Collection Rule for VMs'

// Windows Event Log configuration
param windowsEventLogStreams array = [
  'Microsoft-ServiceFabricNode/Admin'
  'Microsoft-ServiceFabricNode/Operational'
  'System!*[System[(Level=1 or Level=2 or Level=3)]]'
  'Application!*[Application[(Level=1 or Level=2 or Level=3)]]'
]

// Performance counters configuration
param performanceCounters array = [
  {
    counterName: '% Processor Time'
    objectName: 'Processor'
    instance: '_Total'
  }
  {
    counterName: '% Used Memory'
    objectName: 'Memory'
    instance: '*'
  }
]

// Syslog configuration (for Linux agents)
param syslogFacilities array = []

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dcrName
  location: location
  tags: tags
  properties: {
    description: description
    dataSources: {
      windowsEventLogs: [
        {
          name: 'eventLogsDataSource'
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: windowsEventLogStreams
        }
      ]
      performanceCounters: [
        {
          name: 'perfCounterDataSource'
          streams: [
            'Microsoft-Perf'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            for counter in performanceCounters: 
              '\\\\${counter.objectName}(${counter.instance})\\\\${counter.counterName}'
          ]
        }
      ]
      syslog: !empty(syslogFacilities) ? [
        {
          name: 'syslogDataSource'
          streams: [
            'Microsoft-Syslog'
          ]
          facilityNames: syslogFacilities
          logLevels: [
            'Alert'
            'Critical'
            'Emergency'
            'Error'
            'Notice'
            'Warning'
          ]
        }
      ] : []
    }
    destinations: {
      logAnalytics: [
        {
          name: 'centralLogAnalyticsWorkspace'
          workspaceResourceId: workspaceResourceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Event'
          'Microsoft-Perf'
          'Microsoft-Syslog'
        ]
        destinations: [
          'centralLogAnalyticsWorkspace'
        ]
      }
    ]
  }
}

output dcrId string = dataCollectionRule.id
output dcrName string = dataCollectionRule.name
output dcrImmutableId string = dataCollectionRule.properties.immutableId
