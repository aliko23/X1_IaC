using 'deploy-spoke.bicep'

param workloadName = 'apimtest01'
param env = 'uat'
param vnetHubResourceId = 'ResourceID of the Hub VNet'

param vnetSpokeConfiguration = {
  addressSpace: '10.0.4.0/22'
  subnets: [
    {
      name: 'snet-integration'
      addressPrefix: '10.0.4.0/24'
      routeTable: null
      delegation: 'Microsoft.Web/serverfarms'
    }
    {
      name: 'snet-pep'
      addressPrefix: '10.0.5.0/24'
      routeTable: null
      delegation: null      
    }
    {
      name: 'snet-devops'
      addressPrefix: '10.0.6.0/24'
      routeTable: null
      delegation: null
    }
  ]
}
