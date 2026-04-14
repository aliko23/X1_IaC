# Azure Resource Export - Bicep Modules
## Production Environment - Germany West Central

This project exports Azure resources from resource group `rg-test-prod-gwc-02` to modular Bicep code for Infrastructure as Code management.

**Exported Date:** April 14, 2026  
**Source Subscription:** `aa016cda-255f-44aa-9f0e-284417575b2c`  
**Source Resource Group:** `rg-test-prod-gwc-02`  
**Region:** `germanywestcentral` (Germany West Central)

---

## 📋 Resources Included

### Infrastructure Components

1. **Virtual Network (VNet)**
   - Name: `hedno-vnet-test-prod-gwc-02`
   - Address Space: `10.0.0.0/16`
   - Subnets: Default subnet with address prefix `10.0.0.0/24`

2. **Network Security Group (NSG)**
   - Name: `nsg-test-prod-gwc-001`
   - Rules: RDP (3389), WinRM HTTP (5985), WinRM HTTPS (5986)
   - Default deny all inbound traffic policy

3. **Route Table**
   - Name: `rt-test-prod-gwc-02`
   - BGP Route Propagation: Disabled
   - Custom routes can be configured via parameters

4. **Network Interface Card (NIC)**
   - Name: `vmtestprod001196_z1`
   - Private IP: `10.0.0.4` (Static allocation)
   - Associated with default subnet

### Compute Resources

5. **Managed Disk (OS)**
   - Name: `vmtestprod001_OsDisk_1_c79e16e61dfb47a380bb671e12dcd216`
   - Size: 128 GB
   - SKU: Premium_LRS (SSD)
   - OS Type: Windows

6. **Virtual Machine**
   - Name: `vmtestprod001`
   - Size: Standard_D2s_v3 (2 vCPUs, 8 GB RAM)
   - OS: Windows Server 2022 Datacenter
   - License: Windows Server (BYOL)
   - Security Type: Trusted Launch
   - Boot Diagnostics: Enabled
   - System-assigned Managed Identity: Yes

### Extensions

- **AzureMonitorWindowsAgent** - Azure Monitor agent for telemetry collection
- **AzurePolicyforWindows** - Azure Policy for compliance and configuration management
- **MDE.Windows** - Microsoft Defender for Endpoint

### Monitoring

7. **Data Collection Rule (DCR)**
   - Name: `MSVMI-ama-vmi-default-dcr`
   - Collects: Windows Event Logs, Performance Counters
   - Destination: Log Analytics Workspace

---

## 📁 Directory Structure

```
azure-export-gwc-prod/
├── main.bicep                 # Main orchestration file
├── main.bicepparam           # Parameter file (production values)
├── README.md                 # This file
└── modules/
    ├── vnet.bicep           # Virtual Network module
    ├── nsg.bicep            # Network Security Group module
    ├── routetable.bicep     # Route Table module
    ├── nic.bicep            # Network Interface module
    ├── vm.bicep             # Virtual Machine module (with extensions)
    ├── disk.bicep           # Managed Disk module
    └── dcr.bicep            # Data Collection Rule module
```

---

## 🔧 Prerequisites

1. **Azure CLI** (version 2.50.0 or later)
   ```bash
   az --version
   ```

2. **Bicep CLI** (automatically installed with Azure CLI 2.3.0+)
   ```bash
   az bicep version
   ```

3. **Azure Subscription** with appropriate permissions
   - Owner or Contributor role on the target resource group
   - Ability to assign managed identities (for Azure Policy and MDE extensions)

4. **Key Vault** (optional, for secure password management)
   - If not using secured password approach

---

## 🚀 Deployment Instructions

### 1. Prepare Parameters

Edit `main.bicepparam` with your specific values:

```bicep
param vmAdminUsername = 'youradminuser'
param vmAdminPassword = 'YourSecurePassword123!' # Replace with secure password
param logAnalyticsWorkspaceId = '/subscriptions/{subscriptionId}/resourcegroups/{resourceGroup}/providers/microsoft.operationalinsights/workspaces/{workspaceName}'
param logAnalyticsWorkspaceKey = 'YourWorkspaceKey'
```

**⚠️ Security Best Practice:** Use Azure Key Vault references instead of hardcoding passwords:
```bicep
param vmAdminPassword = '@Microsoft.KeyVault(SecretUri=https://<keyVaultName>.vault.azure.net/secrets/<secretName>)'
```

### 2. Validate the Bicep Files

```bash
# Validate main Bicep file
az bicep build --file main.bicep

# Validate template against subscription
az deployment group validate \
  --resource-group rg-test-prod-gwc-02 \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### 3. Deploy to Azure

```bash
# Set your subscription
az account set --subscription aa016cda-255f-44aa-9f0e-284417575b2c

# Deploy resources
az deployment group create \
  --resource-group rg-test-prod-gwc-02 \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --name bicep-export-deployment-$(date +%s)
```

### 4. Verify Deployment

```bash
# Check deployment status
az deployment group show \
  --resource-group rg-test-prod-gwc-02 \
  --name <deployment-name> \
  --query 'properties.provisioningState'

# List all resources
az resource list --resource-group rg-test-prod-gwc-02 --output table

# Get VM details
az vm show --resource-group rg-test-prod-gwc-02 --name vmtestprod001
```

---

## 📝 Module Details

### vnet.bicep
**Purpose:** Creates Azure Virtual Network with configurable subnets, address spaces, and DNS settings.

**Key Parameters:**
- `location` - Azure region
- `vnetName` - VNet resource name
- `addressPrefixes` - CIDR address spaces
- `subnets` - Array of subnet configurations
- `dnsServers` - Custom DNS server IPs

**Outputs:**
- `vnetId` - Resource ID of VNet
- `vnetName` - Name of VNet

---

### nsg.bicep
**Purpose:** Creates Network Security Group with inbound/outbound rules.

**Key Parameters:**
- `location` - Azure region
- `nsgName` - NSG resource name
- `securityRules` - Array of security rules

**Rule Properties:**
- `name` - Rule identifier
- `protocol` - TCP, UDP, or *
- `sourcePortRange` - Source port or range
- `destinationPortRange` - Destination port or range
- `sourceAddressPrefix` - Source IP address/CIDR
- `destinationAddressPrefix` - Destination IP address/CIDR
- `access` - Allow or Deny
- `priority` - Processing priority (100-4096)
- `direction` - Inbound or Outbound

---

### routetable.bicep
**Purpose:** Creates Route Table for custom routing configuration.

**Key Parameters:**
- `location` - Azure region
- `routeTableName` - Route Table resource name
- `routes` - Array of route configurations
- `disableBgpRoutePropagation` - BGR route propagation setting

**Route Properties:**
- `name` - Route identifier
- `addressPrefix` - Destination CIDR
- `nextHopType` - VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance, None
- `nextHopIpAddress` - Next hop IP (for VirtualAppliance type)

---

### nic.bicep
**Purpose:** Creates Network Interface Card for VMs.

**Key Parameters:**
- `location` - Azure region
- `nicName` - NIC resource name
- `subnetId` - Target subnet resource ID
- `primaryPrivateIpAddress` - Static private IP
- `enableAcceleratedNetworking` - Accelerated networking flag
- `nsgId` - Associated NSG resource ID
- `publicIpId` - Public IP resource ID (optional)

---

### vm.bicep
**Purpose:** Creates Windows Virtual Machine with extensions.

**Key Parameters:**
- `vmName` - VM resource name
- `vmSize` - VM size (e.g., Standard_D2s_v3)
- `nicId` - Network interface resource ID
- `adminUsername` - Local admin username
- `adminPassword` - Local admin password (secure parameter)
- `imagePublisher` - OS image publisher (MicrosoftWindowsServer)
- `imageSku` - OS image SKU (2022-Datacenter)
- `monitoringEnabled` - Enable Azure Monitor agent
- `installMonitoringAgent` - Install monitoring agent
- `installPolicyExtension` - Install Azure Policy extension
- `installMDEExtension` - Install MDE extension

**Extensions Included:**
1. **AzureMonitorWindowsAgent** - Collects telemetry and performance data
2. **AzurePolicyforWindows** - Configuration management and compliance
3. **MDE.Windows** - Endpoint detection and response

---

### disk.bicep
**Purpose:** Creates Managed Disk for VM storage.

**Key Parameters:**
- `location` - Azure region
- `diskName` - Disk resource name
- `diskSizeGb` - Disk size in GB
- `sku` - Disk type (Premium_LRS, Standard_LRS, StandardSSD_LRS, PremiumV2_LRS)
- `osType` - Windows or Linux
- `encryptionEnabled` - Encryption at rest flag

---

### dcr.bicep
**Purpose:** Creates Data Collection Rule for Azure Monitor.

**Key Parameters:**
- `location` - Azure region
- `dcrName` - DCR resource name
- `workspaceResourceId` - Target Log Analytics Workspace ID
- `windowsEventLogStreams` - Windows event log queries
- `performanceCounters` - Performance counter collection

**Data Sources Configured:**
- Windows Event Logs (System, Application)
- Performance Counters (CPU, Memory)
- Syslog (optional, for Linux agents)

---

## 🔐 Security Recommendations

### 1. Network Security
- Review NSG rules and restrict source IPs to specific networks
- Consider using Application Security Groups for better rule management
- Implement Network Security Group Flow Logs for traffic monitoring

### 2. VM Security
- Change default admin credentials regularly
- Consider disabling RDP and using Azure Bastion instead
- Update Windows Server to latest patches regularly
- Enable disk encryption for sensitive data

### 3. Authentication & Access
- Use Managed Identities for Azure service authentication
- Implement Azure RBAC roles with least privilege principle
- Store credentials in Azure Key Vault (not in parameter files)
- Use multi-factor authentication for admin accounts

### 4. Monitoring & Logging
- Enable diagnostic settings on all resources
- Configure log retention policies in Log Analytics Workspace
- Set up alerts for suspicious activities
- Use Microsoft Defender for Cloud for security monitoring

---

## 🔄 Customization

### Add Custom Routes

Edit `main.bicepparam` and modify `routeTableConfig`:

```bicep
param routeTableConfig = {
  name: 'rt-test-prod-gwc-02'
  routes: [
    {
      name: 'ToOnPremises'
      addressPrefix: '192.168.0.0/16'
      nextHopType: 'VirtualNetworkGateway'
    }
    {
      name: 'ToInternet'
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'Internet'
    }
  ]
  disableBgpRoutePropagation: false
}
```

### Add Additional NSG Rules

Extend the `securityRules` array in `main.bicepparam`:

```bicep
{
  name: 'AllowHTTPS'
  description: 'Allow HTTPS traffic'
  protocol: 'Tcp'
  sourcePortRange: '*'
  destinationPortRange: '443'
  sourceAddressPrefix: '*'
  destinationAddressPrefix: '*'
  access: 'Allow'
  priority: 200
  direction: 'Inbound'
}
```

### Add Additional Subnets

Modify `vnetConfig.subnets`:

```bicep
subnets: [
  {
    name: 'default'
    addressPrefix: '10.0.0.0/24'
    nsgId: ''
    routeTableId: ''
  }
  {
    name: 'database'
    addressPrefix: '10.0.1.0/24'
    nsgId: ''
    routeTableId: ''
  }
]
```

### Change VM Size

Update `vmConfig.size` in `main.bicepparam`:

```bicep
param vmConfig = {
  size: 'Standard_D4s_v3'  // Changed from D2s_v3
  // ... other properties
}
```

---

## 📊 Monitoring & Health Checks

### Azure Monitor Configuration

1. **Create Log Analytics Workspace:**
   ```bash
   az monitor log-analytics workspace create \
     --resource-group rg-test-prod-gwc-02 \
     --workspace-name law-test-prod
   ```

2. **Get Workspace Details:**
   ```bash
   az monitor log-analytics workspace show \
     --resource-group rg-test-prod-gwc-02 \
     --workspace-name law-test-prod
   ```

3. **Query Collected Data:**
   ```kusto
   // Performance counter data
   Perf
   | where ObjectName in ("Processor", "Memory")
   | summarize AvgValue = avg(CounterValue) by ObjectName, Computer
   | order by Computer

   // Event Log data
   Event
   | where EventLevelName in ("Error", "Warning")
   | summarize Count = count() by EventID, Source
   ```

---

## 🔍 Troubleshooting

### Deployment Fails with Validation Error

```bash
# Enable debug logging
az deployment group create \
  --debug \
  --resource-group rg-test-prod-gwc-02 \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### VM Extension Installation Issues

```bash
# Check extension status
az vm extension list \
  --resource-group rg-test-prod-gwc-02 \
  --vm-name vmtestprod001

# Get extension details
az vm extension show \
  --resource-group rg-test-prod-gwc-02 \
  --vm-name vmtestprod001 \
  --name AzureMonitorWindowsAgent
```

### Network Configuration Issues

```bash
# Verify NIC configuration
az network nic show \
  --resource-group rg-test-prod-gwc-02 \
  --name vmtestprod001196_z1

# Test NSG rules
az network nsg rule list \
  --resource-group rg-test-prod-gwc-02 \
  --nsg-name nsg-test-prod-gwc-001
```

---

## 🧹 Cleanup

To remove all deployed resources:

```bash
# Delete entire resource group (all resources will be deleted)
az group delete \
  --name rg-test-prod-gwc-02 \
  --yes \
  --no-wait

# Or delete specific resources
az vm delete \
  --resource-group rg-test-prod-gwc-02 \
  --name vmtestprod001 \
  --yes
```

---

## 📚 Additional Resources

- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)
- [Azure VM Best Practices](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/tutorial-manage-vm)
- [Azure Monitor Documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/overview)
- [Network Security Groups](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/architecture/framework/)

---

## 📝 Notes

- All resources use managed identities where applicable
- Default tags include environment, region, and metadata
- Cost optimization: Review SKU selections based on actual workload requirements
- Compliance: Ensure configurations meet organizational security policies
- Disaster Recovery: Configure backup and replication as needed

---

**Last Updated:** April 14, 2026  
**Created By:** Bicep Export Process  
**Version:** 1.0
