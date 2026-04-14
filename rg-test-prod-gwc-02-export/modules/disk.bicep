// Managed Disk Module
// Exports: vmtestprod001_OsDisk_1_c79e16e61dfb47a380bb671e12dcd216

param location string
param diskName string
param diskSizeGB int = 127
param osType string = 'Windows'
param skuName string = 'StandardSSD_LRS'
param zones array = ['1']
param environment string = 'prod'

// Image reference for creation
param imagePublisher string = 'MicrosoftWindowsServer'
param imageOffer string = 'WindowsServer'
param imageSku string = '2022-datacenter-azure-edition'
param imageVersion string = 'latest'

resource managedDisk 'Microsoft.Compute/disks@2023-10-02' = {
  name: diskName
  location: location
  zones: zones
  sku: {
    name: skuName
  }
  properties: {
    osType: osType
    creationData: {
      createOption: 'FromImage'
      imageReference: {
        id: resourceId('Microsoft.Compute/locations/publishers/artifacttypes/offers/skus/versions', location, imagePublisher, 'VMImage', imageOffer, imageSku, imageVersion)
      }
    }
    diskSizeGB: diskSizeGB
    encryption: {
      type: 'EncryptionAtRestWithPlatformKey'
    }
    networkAccessPolicy: 'AllowAll'
    publicNetworkAccess: 'Enabled'
    hyperVGeneration: 'V2'
  }
  tags: {
    environment: environment
  }
}

output diskId string = managedDisk.id
output diskName string = managedDisk.name
