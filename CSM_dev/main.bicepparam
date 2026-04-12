using 'main.bicep'

param workloadName = 'csm'
param sharedWorkloadName = 'shared'
param env = 'qa'

param apimConfiguration = {
  publisherName: 'HEDNO'
  publisherEmail: 'hedno'
}

param vnetSharedConfiguration = {
  addressSpace: '10.0.0.0/22'
  // if need for more subnets, place the APIM subnet first!
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
