using './main.bicep'

// ============================================================================
// Production Environment Parameters
// Resource Group: rg-test-prod-gwc-02
// Region: Germany West Central
// ============================================================================

param location = 'germanywestcentral'
param environment = 'prod'
param namePrefix = 'test'

param commonTags = {
  environment: 'prod'
  region: 'germanywestcentral'
  resourceGroup: 'rg-test-prod-gwc-02'
  subscriptionId: 'aa016cda-255f-44aa-9f0e-284417575b2c'
  createdBy: 'Bicep-Export'
  costCenter: ''
  owner: ''
}

// ============================================================================
// Virtual Network Configuration
// ============================================================================

param vnetConfig = {
  name: 'hedno-vnet-test-prod-gwc-02'
  addressPrefixes: [
    '10.0.0.0/16'
  ]
  subnets: [
    {
      name: 'default'
      addressPrefix: '10.0.0.0/24'
      nsgId: ''
      routeTableId: ''
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
    }
  ]
  dnsServers: [
    '168.63.129.16'
  ]
}

// ============================================================================
// Network Security Group Configuration
// ============================================================================

param nsgConfig = {
  name: 'nsg-test-prod-gwc-001'
  rules: [
    {
      name: 'AllowRDP'
      description: 'Allow Remote Desktop Protocol from any source'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3389'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
    {
      name: 'AllowWinRMHTTP'
      description: 'Allow WinRM over HTTP'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '5985'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 101
      direction: 'Inbound'
    }
    {
      name: 'AllowWinRMHTTPS'
      description: 'Allow WinRM over HTTPS'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '5986'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 102
      direction: 'Inbound'
    }
    {
      name: 'DenyAllInbound'
      description: 'Deny all other inbound traffic'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Deny'
      priority: 4096
      direction: 'Inbound'
    }
  ]
}

// ============================================================================
// Route Table Configuration
// ============================================================================

param routeTableConfig = {
  name: 'rt-test-prod-gwc-02'
  routes: []
  disableBgpRoutePropagation: false
}

// ============================================================================
// Network Interface Configuration
// ============================================================================

param nicConfig = {
  name: 'vmtestprod001196_z1'
  primaryPrivateIpAddress: '10.0.0.4'
  enableAcceleratedNetworking: false
  enableIpForwarding: false
  dnsServers: []
}

// ============================================================================
// Managed Disk Configuration
// ============================================================================

param osDiskConfig = {
  name: 'vmtestprod001_OsDisk_1_c79e16e61dfb47a380bb671e12dcd216'
  diskSizeGb: 128
  sku: 'Premium_LRS'
  osType: 'Windows'
}

// ============================================================================
// Virtual Machine Configuration
// ============================================================================

param vmConfig = {
  name: 'vmtestprod001'
  size: 'Standard_D2s_v3'
  imagePublisher: 'MicrosoftWindowsServer'
  imageOffer: 'WindowsServer'
  imageSku: '2022-Datacenter'
  imageVersion: 'latest'
  licenseType: 'Windows_Server'
}

param vmAdminUsername = 'azureadmin'

// IMPORTANT: Replace with actual password or use Key Vault reference
param vmAdminPassword = ''

// ============================================================================
// Monitoring Configuration
// ============================================================================

// Provide the Log Analytics Workspace Resource ID
// Format: /subscriptions/{subscriptionId}/resourcegroups/{resourceGroup}/providers/microsoft.operationalinsights/workspaces/{workspaceName}
param logAnalyticsWorkspaceId = ''
param logAnalyticsWorkspaceKey = ''

param dcrConfig = {
  name: 'MSVMI-ama-vmi-default-dcr'
  description: 'Default Data Collection Rule for Azure Monitor Agent - Production Environment'
}
