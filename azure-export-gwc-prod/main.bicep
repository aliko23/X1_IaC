// Main Orchestration File
// Deploys all resources for Production environment in Germany West Central
// Resource Group: rg-test-prod-gwc-02

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Azure region for resource deployment')
param location string = 'germanywestcentral'

@description('Environment identifier')
param environment string = 'prod'

@description('Resource naming prefix')
param namePrefix string = 'test'

@description('Common resource tags')
param commonTags object = {
  environment: environment
  region: location
  createdBy: 'Bicep-Export'
  createdDate: utcNow('u')
}

// ============================================================================
// Virtual Network Configuration
// ============================================================================

@description('Virtual Network configuration')
param vnetConfig object = {
  name: 'hedno-vnet-${namePrefix}-${environment}-gwc-02'
  addressPrefixes: [
    '10.0.0.0/16'
  ]
  subnets: [
    {
      name: 'default'
      addressPrefix: '10.0.0.0/24'
      nsgId: ''
      routeTableId: ''
    }
  ]
  dnsServers: []
}

// ============================================================================
// Network Security Group Configuration
// ============================================================================

@description('Network Security Group configuration')
param nsgConfig object = {
  name: 'nsg-${namePrefix}-${environment}-gwc-001'
  rules: [
    // Allow RDP
    {
      name: 'AllowRDP'
      description: 'Allow Remote Desktop Protocol'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3389'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
    // Allow WinRM HTTP
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
    // Allow WinRM HTTPS
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
  ]
}

// ============================================================================
// Route Table Configuration
// ============================================================================

@description('Route Table configuration')
param routeTableConfig object = {
  name: 'rt-${namePrefix}-${environment}-gwc-02'
  routes: []
  disableBgpRoutePropagation: false
}

// ============================================================================
// Network Interface Configuration
// ============================================================================

@description('Network Interface configuration')
param nicConfig object = {
  name: 'vmtestprod001196_z1'
  primaryPrivateIpAddress: '10.0.0.4'
  enableAcceleratedNetworking: false
  enableIpForwarding: false
  dnsServers: []
}

// ============================================================================
// Managed Disk Configuration
// ============================================================================

@description('OS Managed Disk configuration')
param osDiskConfig object = {
  name: 'vmtestprod001_OsDisk_1_c79e16e61dfb47a380bb671e12dcd216'
  diskSizeGb: 128
  sku: 'Premium_LRS'
  osType: 'Windows'
}

// ============================================================================
// Virtual Machine Configuration
// ============================================================================

@description('Virtual Machine configuration')
param vmConfig object = {
  name: 'vmtestprod001'
  size: 'Standard_D2s_v3'
  imagePublisher: 'MicrosoftWindowsServer'
  imageOffer: 'WindowsServer'
  imageSku: '2022-Datacenter'
  imageVersion: 'latest'
  licenseType: 'Windows_Server'
}

@description('VM Admin Username')
param vmAdminUsername string = 'azureadmin'

@description('VM Admin Password')
@minLength(12)
@secure()
param vmAdminPassword string

// ============================================================================
// Monitoring Configuration
// ============================================================================

@description('Log Analytics Workspace resource ID for monitoring')
param logAnalyticsWorkspaceId string = ''

@description('Log Analytics Workspace key for monitoring')
@secure()
param logAnalyticsWorkspaceKey string = ''

@description('Data Collection Rule configuration')
param dcrConfig object = {
  name: 'MSVMI-ama-vmi-default-dcr'
  description: 'Default Data Collection Rule for Azure Monitor Agent'
}

// ============================================================================
// Resource Deployment
// ============================================================================

// Deploy Network Security Group
module nsgModule 'modules/nsg.bicep' = {
  name: 'nsg-deployment'
  params: {
    location: location
    nsgName: nsgConfig.name
    securityRules: nsgConfig.rules
    tags: commonTags
  }
}

// Deploy Route Table
module routeTableModule 'modules/routetable.bicep' = {
  name: 'routetable-deployment'
  params: {
    location: location
    routeTableName: routeTableConfig.name
    routes: routeTableConfig.routes
    disableBgpRoutePropagation: routeTableConfig.disableBgpRoutePropagation
    tags: commonTags
  }
}

// Deploy Virtual Network with subnets (after NSG and Route Table)
module vnetModule 'modules/vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    location: location
    vnetName: vnetConfig.name
    addressPrefixes: vnetConfig.addressPrefixes
    subnets: [
      for subnet in vnetConfig.subnets: {
        name: subnet.name
        addressPrefix: subnet.addressPrefix
        nsgId: nsgModule.outputs.nsgId
        routeTableId: routeTableModule.outputs.routeTableId
      }
    ]
    dnsServers: vnetConfig.dnsServers
    tags: commonTags
  }
  dependsOn: [
    nsgModule
    routeTableModule
  ]
}

// Deploy Managed Disk for OS
module osDiskModule 'modules/disk.bicep' = {
  name: 'disk-deployment'
  params: {
    location: location
    diskName: osDiskConfig.name
    diskSizeGb: osDiskConfig.diskSizeGb
    sku: osDiskConfig.sku
    osType: osDiskConfig.osType
    tags: commonTags
  }
}

// Deploy Network Interface (after VNet)
module nicModule 'modules/nic.bicep' = {
  name: 'nic-deployment'
  params: {
    location: location
    nicName: nicConfig.name
    subnetId: '${vnetModule.outputs.vnetId}/subnets/${vnetConfig.subnets[0].name}'
    primaryPrivateIpAddress: nicConfig.primaryPrivateIpAddress
    nsgId: nsgModule.outputs.nsgId
    enableAcceleratedNetworking: nicConfig.enableAcceleratedNetworking
    enableIpForwarding: nicConfig.enableIpForwarding
    dnsServers: nicConfig.dnsServers
    tags: commonTags
  }
  dependsOn: [
    vnetModule
    nsgModule
  ]
}

// Deploy Virtual Machine with extensions (after NIC)
module vmModule 'modules/vm.bicep' = {
  name: 'vm-deployment'
  params: {
    location: location
    vmName: vmConfig.name
    vmSize: vmConfig.size
    nicId: nicModule.outputs.nicId
    osDiskName: osDiskConfig.name
    osDiskSizeGb: osDiskConfig.diskSizeGb
    osDiskStorageType: osDiskConfig.sku
    publisher: vmConfig.imagePublisher
    offer: vmConfig.imageOffer
    sku: vmConfig.imageSku
    version: vmConfig.imageVersion
    licenseType: vmConfig.licenseType
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
    monitoringEnabled: !empty(logAnalyticsWorkspaceId)
    monitoringWorkspaceId: logAnalyticsWorkspaceId
    monitoringWorkspaceKey: logAnalyticsWorkspaceKey
    installMonitoringAgent: !empty(logAnalyticsWorkspaceId)
    installPolicyExtension: true
    installMDEExtension: true
    tags: commonTags
  }
  dependsOn: [
    nicModule
  ]
}

// Deploy Data Collection Rule (if monitoring is configured)
module dcrModule 'modules/dcr.bicep' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'dcr-deployment'
  params: {
    location: location
    dcrName: dcrConfig.name
    workspaceResourceId: logAnalyticsWorkspaceId
    description: dcrConfig.description
    tags: commonTags
  }
}

// ============================================================================
// Outputs
// ============================================================================

output vnetId string = vnetModule.outputs.vnetId
output vnetName string = vnetModule.outputs.vnetName
output nsgId string = nsgModule.outputs.nsgId
output routeTableId string = routeTableModule.outputs.routeTableId
output nicId string = nicModule.outputs.nicId
output vmId string = vmModule.outputs.vmId
output vmName string = vmModule.outputs.vmName
output vmPrincipalId string = vmModule.outputs.principalId
output osDiskId string = osDiskModule.outputs.diskId
output dcrId string = !empty(logAnalyticsWorkspaceId) ? dcrModule.outputs.dcrId : ''
