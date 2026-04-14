using './main.bicep'

param location = 'germanywestcentral'
param environment = 'prod'
param resourceGroupName = 'rg-test-prod-gwc-02'

// VM Configuration
param vmName = 'vmtestprod001'
param vmSize = 'Standard_B2as_v2'
param vmAdminUsername = 'adminlocal'
// Note: Provide vmAdminPassword at deployment time using -p parameter or environment variable
// Example: az deployment group create --parameters vmAdminPassword=$(pwsh -Command Read-Host -AsSecureString) ...
param computerName = 'vmtestprod001'

// Network Configuration
param vnetName = 'hedno-vnet-test-prod-gwc-02'
param vnetAddressPrefix = '10.19.90.224/28'
param subnetName = 'snet-test-prod-gwc-001'
param subnetAddressPrefix = '10.19.90.224/28'
param nicName = 'vmtestprod001196_z1'
param nsgName = 'nsg-test-prod-gwc-001'
param routeTableName = 'rt-test-prod-gwc-02'

// DNS Servers
param dnsServers = [
  '10.19.66.4'
  '10.19.66.5'
]

// Storage Configuration
param diskName = 'vmtestprod001_OsDisk_1_c79e16e61dfb47a380bb671e12dcd216'
param diskSizeGB = 127

// Monitoring Configuration
param dcrName = 'MSVMI-ama-vmi-default-dcr'
param lawWorkspaceResourceId = '/subscriptions/f277b017-a5e1-41b7-b016-3ce52c11a68f/resourcegroups/hedno-mgmt-gwc/providers/microsoft.operationalinsights/workspaces/hedno-monitoring-law-gwc'
param lawWorkspaceId = 'a72a9cdf-95c0-4598-9036-8b1498bfedb0'

// Route Table Tags
param routeTableTags = {
  ApplicationName: 'Expressroute'
  Requestor: 't.chatzithomaoglou@deddie.gr'
}
