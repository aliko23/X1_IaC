# Java Function App with Private Endpoint and VNet Injection

This Bicep template deploys a complete Java Function App infrastructure with enterprise-grade networking and security features.

## Architecture Overview

```
┌─────────────────────────────────────┐
│   Virtual Network (10.0.0.0/16)    │
├─────────────────────────────────────┤
│  Function App Subnet (10.0.1.0/24) │
│  ├─ Java Function App               │
│  └─ Delegated to Microsoft.Web      │
├─────────────────────────────────────┤
│  Private Endpoint Subnet            │
│  (10.0.2.0/24)                      │
│  ├─ Function App PE                 │
│  ├─ Storage Blob PE                 │
│  ├─ Storage File PE                 │
│  ├─ Storage Table PE                │
│  └─ Storage Queue PE                │
└─────────────────────────────────────┘
         │
         ├─ Storage Account
         │  (access only via PE)
         │
         └─ App Service Plan
```

## Features

- **Java 17 Runtime**: Pre-configured for Java 17 (customizable to 8, 11, or 21)
- **VNet Injection**: Function App integrated into virtual network for outbound traffic control
- **Private Endpoints**: 
  - Secure Function App connectivity
  - All Storage services protected (blob, files, tables, queues)
- **Linux App Service Plan**: Cost-effective Linux-based hosting
- **Managed Storage**: Azure Storage Account for Function App backend with private access
- **System-Assigned Identity**: Managed identity for Function App authentication
- **Security Best Practices**:
  - HTTPS only enforcement
  - TLS 1.2 minimum
  - Service endpoints for storage and Key Vault
  - Private endpoint network policies disabled for PE subnet
  - Storage account network access restricted (Deny by default)

## Modules

### `_modules/vnet.bicep`
Creates Virtual Network with two subnets:
- **Function App Subnet**: Delegated to Microsoft.Web/serverFarms
- **Private Endpoint Subnet**: Configured for private endpoints

**Key Parameters:**
- `vnetName`: Name of the virtual network
- `addressPrefix`: VNet CIDR (default: 10.0.0.0/16)
- `functionAppSubnetPrefix`: Function App subnet CIDR (default: 10.0.1.0/24)
- `privateEndpointSubnetPrefix`: Private endpoint subnet CIDR (default: 10.0.2.0/24)

### `_modules/storage.bicep`
Creates Storage Account for Function App backend with network security.

**Key Parameters:**
- `storageAccountName`: Globally unique storage account name (required)
- `storageSku`: Storage account SKU (default: Standard_LRS)

**Security Features:**
- Secure transfer (HTTPS only)
- Minimum TLS 1.2
- Blob public access disabled
- Network access denied by default (access only through private endpoints)
- AzureServices bypass for platform services

### `_modules/app-service-plan.bicep`
Creates Linux App Service Plan for hosting Function App.

**Key Parameters:**
- `appServicePlanName`: Name of the App Service Plan
- `skuName`: SKU tier (P1v2, P2v2, P3v2, P1v3, P2v3, P3v3, EP1, EP2, EP3)
- `capacity`: Number of worker instances
- `kind`: 'Linux' (optimized for Java)

### `_modules/function-app.bicep`
Creates Java Function App with VNet integration.

**Key Parameters:**
- `functionAppName`: Name of the Function App
- `appServicePlanId`: Reference to App Service Plan
- `storageAccountConnectionString`: Storage connection string
- `vnetSubnetId`: Subnet for VNet integration
- `javaVersion`: Java version (8, 11, 17, 21)
- `httpsOnly`: HTTPS enforcement (default: true)

**App Configuration:**
- Runtime: Java 17 (customizable)
- Always On: Enabled
- App Settings:
  - `AzureWebJobsStorage`: Storage connection
  - `FUNCTIONS_WORKER_RUNTIME`: java
  - `FUNCTIONS_EXTENSION_VERSION`: ~4
  - CORS enabled for all origins

### `_modules/private-endpoint.bicep`
Creates Private Endpoint for Function App.

**Key Parameters:**
- `privateEndpointName`: Name of the private endpoint
- `functionAppId`: Function App resource ID
- `subnetId`: Subnet for private endpoint
- `groupIds`: Service groups (default: ['sites'])

### `_modules/storage-private-endpoints.bicep`
Creates Private Endpoints for all Storage Account services (blob, file, table, queue).

**Key Parameters:**
- `privateEndpointNamePrefix`: Name prefix for private endpoints
- `storageAccountId`: Storage Account resource ID
- `subnetId`: Subnet for private endpoints

**Services Secured:**
- **Blob**: Private endpoint for blob storage
- **File**: Private endpoint for file shares
- **Table**: Private endpoint for table storage
- **Queue**: Private endpoint for queue storage

## Deployment

### Prerequisites
- Azure subscription with appropriate permissions
- Azure CLI or Bicep CLI installed
- Resource Group already created

### Using Azure CLI

```bash
# Validate the template
az deployment group validate \
  --resource-group <resourceGroupName> \
  --template-file main.bicep \
  --parameters main.bicepparam

# Deploy the template
az deployment group create \
  --resource-group <resourceGroupName> \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### Using Azure PowerShell

```powershell
# Validate the template
Test-AzResourceGroupDeployment `
  -ResourceGroupName <resourceGroupName> `
  -TemplateFile main.bicep `
  -TemplateParameterFile main.bicepparam

# Deploy the template
New-AzResourceGroupDeployment `
  -ResourceGroupName <resourceGroupName> `
  -TemplateFile main.bicep `
  -TemplateParameterFile main.bicepparam
```

## Configuration

### Customizing Parameters

Edit `main.bicepparam` to customize:

```bicep
param location = 'eastus'                          # Azure region
param environment = 'dev'                          # Environment name
param applicationName = 'javaFunc'                # Application name prefix

param vnetConfig = {
  addressPrefix: '10.0.0.0/16'                   # VNet CIDR
  functionAppSubnetPrefix: '10.0.1.0/24'         # Function subnet CIDR
  privateEndpointSubnetPrefix: '10.0.2.0/24'    # PE subnet CIDR
}

param storageSku = 'Standard_LRS'                 # Storage SKU
param appServicePlanSku = 'P1v2'                  # App Service Plan SKU
param javaVersion = '17'                          # Java version
param capacity = 1                                # Number of instances
```

### Changing Java Version

To use a different Java version, modify the parameter file:

```bicep
param javaVersion = '21'  # Change to 8, 11, 17, or 21
```

### Adjusting Performance

For higher performance environments, change the App Service Plan SKU:

```bicep
param appServicePlanSku = 'P3v3'  # For production
```

Supported SKUs:
- **Development**: P1v2, P2v2
- **Staging**: P2v3, P3v2
- **Production**: P3v3, EP2, EP3

## Networking Details

### VNet Integration
The Function App is deployed with VNet integration, allowing:
- Outbound traffic routing through VNet
- Access to resources in the VNet
- Control over network security policies
- Integration with Network Security Groups (if needed)

### Private Endpoints
The infrastructure includes private endpoints for:
- **Function App Sites**: Secure connectivity to Function App
- **Storage Blob**: Access to blob storage privately
- **Storage File**: Access to file shares privately
- **Storage Table**: Access to table storage privately
- **Storage Queue**: Access to queue storage privately

All private endpoints are deployed in the Private Endpoint Subnet (10.0.2.0/24) and communicate over the Microsoft backbone network, with no exposure to the public internet.

### Storage Network Security
The Storage Account is configured with:
- **Default Action**: Deny all public access
- **Bypass**: AzureServices (platform services can bypass rules)
- **Network Access**: Only through private endpoints
- **TLS 1.2+**: All transfers encrypted

### Service Endpoints
Configured service endpoints on Function App subnet:
- **Microsoft.Storage**: Direct connectivity to Storage (backup access)
- **Microsoft.KeyVault**: Access to Key Vault if needed

## Security Considerations

1. **Network Isolation**: Function App is not publicly exposed; access only through private endpoint
2. **Storage Security**: 
   - Public blob access disabled
   - HTTPS only
   - Minimum TLS 1.2
3. **HTTPS Enforcement**: All Function App traffic must be HTTPS
4. **Runtime Security**: Latest Java runtime versions support current security patches

## Outputs

The deployment provides the following outputs:

```json
{
  "deploymentDetails": {
    "vnetId": "resource ID of VNet",
    "vnetName": "name of VNet",
    "storageAccountId": "resource ID of storage",
    "storageAccountName": "name of storage account",
    "appServicePlanId": "resource ID of ASP",
    "functionAppPrivateEndpointId": "resource ID of Function App PE",
    "storagePrivateEndpoints": {
      "blobEndpointId": "resource ID of Blob PE",
      "fileEndpointId": "resource ID of File PE",
      "tableEndpointId": "resource ID of Table PE",
      "queueEndpointId": "resource ID of Queue PE"
    },
    "functionAppPrincipalId": "managed identity principal ID"
  },
  "functionAppResourceId": "Function App resource ID",
  "functionAppName": "Function App name",
  "functionAppUrl": "Function App default URL",
  "vnetId": "VNet resource ID",
  "storageAccountName": "Storage account name",
  "storagePrivateEndpoints": {
    "blob": "Blob private endpoint name",
    "file": "File private endpoint name",
    "table": "Table private endpoint name",
    "queue": "Queue private endpoint name"
  }
  "functionAppUrl": "Function App default URL",
  "vnetId": "VNet resource ID",
  "storageAccountName": "Storage account name"
}
```

## Post-Deployment Steps

1. **Configure DNS for Private Endpoints**: 
   - Create private DNS zones for:
     - `privatelink.blob.core.windows.net` (Blob)
     - `privatelink.file.core.windows.net` (File shares)
     - `privatelink.table.core.windows.net` (Tables)
     - `privatelink.queue.core.windows.net` (Queues)
     - `privatelink.azurewebsites.net` (Function App)
   - Create A records pointing to private endpoint IPs
   - Link private DNS zones to the VNet

2. **Deploy Java Code**: Publish your Java Functions using Azure CLI or VS Code extension

3. **Secure Storage Access**: Function App can now access storage only through private endpoints

4. **Network Security**: Storage account is not publicly accessible; all access is through private endpoints

5. **Monitoring**: Set up Application Insights if needed (optional)

## Accessing the Function App

### Public Access (Requires DNS Configuration)
1. Create Private DNS Zone for `functionapp.azurewebsites.net`
2. Create A record pointing to Private Endpoint IP
3. Access via Function App URL

### Development/Testing (Without DNS)
Use Azure CLI to get the Function App details:
```bash
az functionapp show --resource-group <rg> --name <functionAppName>
```

## Troubleshooting

### Function App Not Starting
- Check Java version compatibility
- Verify storage account connection string
- Review Function App logs in Azure Portal

### Private Endpoint Connectivity Issues
- Verify subnet configuration
- Check network policies
- Ensure DNS resolution (if using private DNS)

### Performance Issues
- Consider increasing App Service Plan capacity
- Monitor CPU and memory usage
- Review Java heap size settings

## Cost Estimation

Approximate monthly costs (US East, 1 instance):
- App Service Plan (P1v2): $73/month
- Storage Account (Standard): $1-5/month
- Private Endpoint: $7/month
- **Total: ~$80-85/month** (excluding data transfer)

For exact pricing, use [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)

## Best Practices

1. **Use Managed Identity**: Replace connection strings with managed identity authentication
2. **Enable Diagnostics**: Configure Application Insights for monitoring
3. **Network Security**: Use NSGs to restrict traffic to specific sources
4. **Auto-Scaling**: Configure scale settings based on workload patterns
5. **Backup Strategy**: Regular backups of function code and configuration
6. **Update Regularly**: Keep Java runtime and Function App runtime updated

## Additional Resources

- [Azure Functions Java Developer Guide](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-java)
- [App Service VNet Integration](https://docs.microsoft.com/en-us/azure/app-service/web-sites-integrate-with-vnet)
- [Private Endpoints Best Practices](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)

## Support

For issues or questions:
1. Check Azure Function App logs
2. Review VNet configuration
3. Verify storage account connectivity
4. Consult Azure documentation linked above

## License

These Bicep templates are provided as-is for internal use.
