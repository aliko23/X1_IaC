// Managed Disk Module
// Creates a managed disk for VM storage

param location string
param diskName string
param diskSizeGb int
param tags object = {}

// Disk properties
param osType string = 'Windows' // Windows or Linux
param sku string = 'Premium_LRS' // Premium_LRS, Standard_LRS, StandardSSD_LRS, PremiumV2_LRS
param createOption string = 'Empty' // Empty, Copy, FromImage, Restore, Upload

// Encryption settings
param encryptionEnabled bool = false

resource managedDisk 'Microsoft.Compute/disks@2023-10-02' = {
  name: diskName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    creationData: {
      createOption: createOption
    }
    diskSizeGB: diskSizeGb
    osType: osType
    encryption: encryptionEnabled ? {
      type: 'EncryptionAtRestWithPlatformKey'
    } : null
    publicNetworkAccess: 'Enabled'
  }
}

output diskId string = managedDisk.id
output diskName string = managedDisk.name
