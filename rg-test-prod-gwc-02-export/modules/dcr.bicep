// Data Collection Rule Module
// Enables VM Insights data collection for performance monitoring

param location string
param dcrName string
param description string = 'Data collection rule for VM Insights.'
param workspaceResourceId string

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: dcrName
  location: location
  kind: 'Linux'
  properties: {
    description: description
    dataSources: {
      performanceCounters: [
        {
          name: 'VMInsightsPerfCounters'
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\VmInsights\\DetailedMetrics'
          ]
          streams: [
            'Microsoft-InsightsMetrics'
          ]
        }
      ]
      extensions: [
        {
          name: 'DependencyAgentDataSource'
          extensionName: 'DependencyAgent'
          extensionSettings: {}
          streams: [
            'Microsoft-ServiceMap'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'VMInsightsPerf-Logs-Dest'
          workspaceResourceId: workspaceResourceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
      {
        streams: [
          'Microsoft-ServiceMap'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
    ]
  }
}

output dcrId string = dataCollectionRule.id
output dcrName string = dataCollectionRule.name
