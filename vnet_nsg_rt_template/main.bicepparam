using './main.bicep'

// Virtual Network Configuration
param vnetName = 'vnet-prod-gwc-01'
param resourceGroupName = 'rg-test-prod-gwc-01'
param location = 'germanywestcentral'
param vnetAddressSpace = '10.0.0.0/16'

// Subnet Configuration with NSG and Route Table Names
param subnets = [
  {
    name: 'snet-web-prod-01'
    addressPrefix: '10.0.1.0/24'
    nsgName: 'nsg-web-prod-01'
    rtName: 'rt-web-prod-01'
  }
  {
    name: 'snet-app-prod-01'
    addressPrefix: '10.0.2.0/24'
    nsgName: 'nsg-app-prod-01'
    rtName: 'rt-app-prod-01'
  }
  {
    name: 'snet-db-prod-01'
    addressPrefix: '10.0.3.0/24'
    nsgName: 'nsg-db-prod-01'
    rtName: 'rt-db-prod-01'
  }
]

// Tags
param tags = {
  environment: 'production'
  project: 'network-infrastructure'
  createdBy: 'bicep'
  costCenter: 'IT'
  owner: 'NetworkTeam'
}
