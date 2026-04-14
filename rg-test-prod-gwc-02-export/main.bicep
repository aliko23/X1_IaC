// Main Orchestration File for rg-test-prod-gwc-02
// Deploys all resources: VM, networking, monitoring

targetScope = 'resourceGroup'

// Parameters
param location string = 'germanywestcentral'
param environment string = 'prod'

// VM Parameters
param vmName string = 'vmtestprod001'
param vmSize string = 'Standard_B2as_v2'
param vmAdminUsername string
@secure()
param vmAdminPassword string
param computerName string = 'vmtestprod001'

// Network Parameters
param vnetName string = 'hedno-vnet-test-prod-gwc-02'
param vnetAddressPrefix string = '10.19.90.224/28'
param subnetName string = 'snet-test-prod-gwc-001'
param subnetAddressPrefix string = '10.19.90.224/28'
param nicName string = 'vmtestprod001196_z1'
param nsgName string = 'nsg-test-prod-gwc-001'
param routeTableName string = 'rt-test-prod-gwc-02'

// Storage/Disk Parameters
param diskName string = 'vmtestprod001_OsDisk_1_c79e16e61dfb47a380bb671e12dcd216'
param diskSizeGB int = 127

// DNS Parameters
param dnsServers array = [
  '10.19.66.4'
  '10.19.66.5'
]

// Monitoring Parameters
param dcrName string = 'MSVMI-ama-vmi-default-dcr'
param lawWorkspaceResourceId string = '/subscriptions/f277b017-a5e1-41b7-b016-3ce52c11a68f/resourcegroups/hedno-mgmt-gwc/providers/microsoft.operationalinsights/workspaces/hedno-monitoring-law-gwc'
param lawWorkspaceId string = 'a72a9cdf-95c0-4598-9036-8b1498bfedb0'

// Route table custom tags
param routeTableTags object = {
  ApplicationName: 'Expressroute'
  Requestor: 't.chatzithomaoglou@deddie.gr'
}

// ============================================================================
// Deploy Network Security Group
// ============================================================================
module nsgModule 'modules/nsg.bicep' = {
  name: 'nsg-deployment'
  params: {
    location: location
    nsgName: nsgName
    environment: environment
    securityRules: []
  }
}

// ============================================================================
// Deploy Route Table with custom routes
// ============================================================================
module routeTableModule 'modules/routetable.bicep' = {
  name: 'routetable-deployment'
  params: {
    location: location
    routeTableName: routeTableName
    disableBgpRoutePropagation: false
    environment: environment
    routes: [
      {
        name: 'ToInternet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.19.64.132'
          hasBgpOverride: false
        }
      }
    ]
    customTags: routeTableTags
  }
}

// ============================================================================
// Deploy Virtual Network
// ============================================================================
module vnetModule 'modules/vnet.bicep' = {
  params: {
    location: location
    vnetName: vnetName
    addressPrefix: vnetAddressPrefix
    subnetName: subnetName
    subnetAddressPrefix: subnetAddressPrefix
    dnsServers: dnsServers
    nsgId: nsgModule.outputs.nsgId
    routeTableId: routeTableModule.outputs.routeTableId
    environment: environment
  }
}

// ============================================================================
// Deploy Managed Disk (OS Disk)
// ============================================================================
module diskModule 'modules/disk.bicep' = {
  name: 'disk-deployment'
  params: {
    location: location
    diskName: diskName
    diskSizeGB: diskSizeGB
    osType: 'Windows'
    skuName: 'StandardSSD_LRS'
    zones: ['1']
    environment: environment
    imagePublisher: 'MicrosoftWindowsServer'
    imageOffer: 'WindowsServer'
    imageSku: '2022-datacenter-azure-edition'
    imageVersion: 'latest'
  }
}

// ============================================================================
// Deploy Network Interface
// ============================================================================
module nicModule 'modules/nic.bicep' = {
  params: {
    location: location
    nicName: nicName
    subnetId: vnetModule.outputs.subnetId
    environment: environment
    enableAcceleratedNetworking: true
    privateIPAllocationMethod: 'Dynamic'
  }
}

// ============================================================================
// Deploy Virtual Machine
// ============================================================================
module vmModule 'modules/vm.bicep' = {
  params: {
    location: location
    vmName: vmName
    vmSize: vmSize
    nicIds: [
      nicModule.outputs.nicId
    ]
    diskId: diskModule.outputs.diskId
    adminUsername: vmAdminUsername
    computerName: computerName
    zones: ['1']
    environment: environment
    imageExactVersion: '20348.3932.250705'
    patchMode: 'AutomaticByPlatform'
    assessmentMode: 'AutomaticByPlatform'
    bootDiagnosticsEnabled: true
    enableSystemAssignedIdentity: true
  }
}

// ============================================================================
// Deploy Data Collection Rule
// ============================================================================
module dcrModule 'modules/dcr.bicep' = {
  name: 'dcr-deployment'
  params: {
    location: location
    dcrName: dcrName
    description: 'Data collection rule for VM Insights.'
    workspaceResourceId: lawWorkspaceResourceId
  }
}

// ============================================================================
// Deploy VM Extensions
// ============================================================================
module extensionsModule 'modules/vmextensions.bicep' = {
  name: 'extensions-deployment'
  dependsOn: [
    dcrModule
  ]
  params: {
    vmId: vmModule.outputs.vmId
    vmName: vmName
    location: location
  }
}

// ============================================================================
// Outputs
// ============================================================================
output vmId string = vmModule.outputs.vmId
output vmName string = vmModule.outputs.vmName
output vnetId string = vnetModule.outputs.vnetId
output subnetId string = vnetModule.outputs.subnetId
output nicId string = nicModule.outputs.nicId
output diskId string = diskModule.outputs.diskId
output dcrId string = dcrModule.outputs.dcrId
output nsgId string = nsgModule.outputs.nsgId
output routeTableId string = routeTableModule.outputs.routeTableId
