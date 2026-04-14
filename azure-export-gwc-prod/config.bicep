// Configuration Reference File
// Shared constants and variable definitions for the export

@description('Azure Region Details')
var regionInfo = {
  name: 'germanywestcentral'
  displayName: 'Germany West Central'
  code: 'gwc'
}

@description('Resource Naming Convention')
var namingConvention = {
  environment: 'prod'
  prefix: 'test'
  region: 'gwc'
  separator: '-'
}

@description('VM Size References for Standard D-Series')
var vmSizeReferences = {
  dv3: {
    'Small': 'Standard_D2s_v3'      // 2 vCPUs, 8 GB RAM
    'Medium': 'Standard_D4s_v3'     // 4 vCPUs, 16 GB RAM
    'Large': 'Standard_D8s_v3'      // 8 vCPUs, 32 GB RAM
    'XLarge': 'Standard_D16s_v3'    // 16 vCPUs, 64 GB RAM
  }
  dv5: {
    'Small': 'Standard_D2s_v5'      // 2 vCPUs, 8 GB RAM
    'Medium': 'Standard_D4s_v5'     // 4 vCPUs, 16 GB RAM
    'Large': 'Standard_D8s_v5'      // 8 vCPUs, 32 GB RAM
  }
}

@description('Network Configuration Templates')
var networkTemplates = {
  singleSubnet: {
    addressSpace: '10.0.0.0/16'
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.0.0.0/24'
      }
    ]
  }
  multiSubnet: {
    addressSpace: '10.0.0.0/16'
    subnets: [
      {
        name: 'management'
        addressPrefix: '10.0.0.0/24'
      }
      {
        name: 'application'
        addressPrefix: '10.0.1.0/24'
      }
      {
        name: 'database'
        addressPrefix: '10.0.2.0/24'
      }
    ]
  }
}

@description('Common NSG Rules')
var nsgRules = {
  rdp: {
    name: 'AllowRDP'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '3389'
    access: 'Allow'
    priority: 100
    direction: 'Inbound'
  }
  winrmHttp: {
    name: 'AllowWinRMHTTP'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '5985'
    access: 'Allow'
    priority: 101
    direction: 'Inbound'
  }
  winrmHttps: {
    name: 'AllowWinRMHTTPS'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '5986'
    access: 'Allow'
    priority: 102
    direction: 'Inbound'
  }
  http: {
    name: 'AllowHTTP'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '80'
    access: 'Allow'
    priority: 200
    direction: 'Inbound'
  }
  https: {
    name: 'AllowHTTPS'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    access: 'Allow'
    priority: 201
    direction: 'Inbound'
  }
  denyAll: {
    name: 'DenyAllInbound'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '*'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
    access: 'Deny'
    priority: 4096
    direction: 'Inbound'
  }
}

@description('Windows Server Image References')
var windowsServerImages = {
  'Windows2022': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-Datacenter'
    version: 'latest'
  }
  'Windows2022-Core': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-Datacenter-Core'
    version: 'latest'
  }
  'Windows2019': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2019-Datacenter'
    version: 'latest'
  }
}

@description('Managed Disk SKU Options')
var diskSkuOptions = {
  premiumSSD: 'Premium_LRS'           // Premium SSD - Ultra-high performance
  standardSSD: 'StandardSSD_LRS'      // Standard SSD - Balanced performance/cost
  standardHDD: 'Standard_LRS'         // Standard HDD - Economical option
  premiumV2: 'PremiumV2_LRS'          // Premium SSD v2 - High IOPS
}

@description('Azure Monitor Data Collection Presets')
var dcrPresets = {
  windows: {
    eventLogs: [
      'System!*[System[(Level=1 or Level=2 or Level=3)]]'
      'Application!*[Application[(Level=1 or Level=2 or Level=3)]]'
      'Microsoft-ServiceFabricNode/Admin'
      'Microsoft-ServiceFabricNode/Operational'
    ]
    performanceCounters: [
      {
        objectName: 'Processor'
        counterName: '% Processor Time'
        instance: '_Total'
      }
      {
        objectName: 'Memory'
        counterName: '% Used Memory'
        instance: '*'
      }
      {
        objectName: 'LogicalDisk'
        counterName: '% Disk Time'
        instance: '*'
      }
    ]
  }
  linux: {
    syslogFacilities: [
      'auth'
      'authpriv'
      'cron'
      'daemon'
      'kern'
      'local0'
      'local1'
      'local2'
      'local3'
      'local4'
      'local5'
      'local6'
      'local7'
      'lpr'
      'mail'
      'mark'
      'news'
      'syslog'
      'user'
      'uucp'
    ]
    performanceCounters: [
      {
        objectName: 'Processor'
        counterName: 'CPU utilization'
        instance: '*'
      }
      {
        objectName: 'Memory'
        counterName: 'Available memory'
        instance: '*'
      }
    ]
  }
}

@description('Common Tags')
var commonTags = {
  environment: 'prod'
  region: 'germanywestcentral'
  createdBy: 'Bicep-Export'
  managedBy: 'IaC'
  compliance: 'SOC2'
}

@description('Resource Export Metadata')
var exportMetadata = {
  exportDate: '2026-04-14'
  sourceSubscription: 'aa016cda-255f-44aa-9f0e-284417575b2c'
  sourceResourceGroup: 'rg-test-prod-gwc-02'
  exportVersion: '1.0'
  exportedResources: [
    'Microsoft.Compute/virtualMachines'
    'Microsoft.Network/virtualNetworks'
    'Microsoft.Network/networkSecurityGroups'
    'Microsoft.Network/networkInterfaces'
    'Microsoft.Network/routeTables'
    'Microsoft.Compute/disks'
    'Microsoft.Insights/dataCollectionRules'
    'Microsoft.Compute/virtualMachines/extensions'
  ]
  extensionsIncluded: [
    'AzureMonitorWindowsAgent'
    'AzurePolicyforWindows'
    'MDE.Windows'
  ]
}

// ============================================================================
// Helper Functions
// ============================================================================

@description('Generate resource name with standard naming convention')
func generateResourceName(resourceType string, identifier string) string =>
  '${namingConvention.prefix}-${resourceType}-${namingConvention.environment}-${namingConvention.region}-${identifier}'

@description('Generate resource name with suffix')
func generateResourceNameWithSuffix(resourceType string, identifier string, suffix string) string =>
  '${namingConvention.prefix}-${resourceType}-${namingConvention.environment}-${namingConvention.region}-${identifier}-${suffix}'

@description('Combine tags with resource-specific tags')
func combineTags(resourceTags object) object =>
  union(commonTags, resourceTags)

@description('Format private IP address based on subnet CIDR')
func getPrivateIpFromCidr(subnetNumber int, hostNumber int) string =>
  '10.0.${subnetNumber}.${hostNumber}'
