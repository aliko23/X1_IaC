using 'deploy-shared.bicep'

param workloadName = 'apimtest01'
param env = 'uat'

param vnetSharedConfiguration = {
  addressSpace: '10.0.0.0/22'
  subnets: [
    {
      name: 'snet-apim'
      addressPrefix: '10.0.0.0/24'
      routeTable: null
      delegation: null
    }
    {
      name: 'snet-integration'
      addressPrefix: '10.0.1.0/24'
      routeTable: null
      delegation: 'Microsoft.Web/serverfarms'
    }
    {
      name: 'snet-pep'
      addressPrefix: '10.0.2.0/24'
      routeTable: null
      delegation: null      
    }
    {
      name: 'snet-devops'
      addressPrefix: '10.0.3.0/24'
      routeTable: null
      delegation: null
    }
  ]
}

param apimConfiguration = {
  publisherName: 'kokrassa'
  publisherEmail: 'kokrassa@microsoft.com'
}
