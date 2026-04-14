# Azure IaC Export: rg-test-prod-gwc-02

## Overview

This Bicep module exports all resources from Azure Resource Group **rg-test-prod-gwc-02** (Subscription: aa016cda-255f-44aa-9f0e-284417575b2c) in **Germany West Central** region.

**Exported Resources:**
- Virtual Machine (vmtestprod001) - Standard_B2as_v2, Windows Server 2022
- Virtual Network (hedno-vnet-test-prod-gwc-02) - 10.19.90.224/28
- Network Interface (vmtestprod001196_z1) - Accelerated networking enabled
- Managed Disk (OS Disk) - 127GB, StandardSSD_LRS, Zone 1
- Network Security Group (nsg-test-prod-gwc-001)
- Route Table (rt-test-prod-gwc-02) - With Expressroute route
- Data Collection Rule (MSVMI-ama-vmi-default-dcr) - VM Insights monitoring
- VM Extensions:
  - Azure Monitor Windows Agent
  - Azure Policy for Windows
  - Microsoft Defender for Servers (MDE)

**Network Configuration:**
- Subnet: snet-test-prod-gwc-001 (10.19.90.224/28)
- VNet Peerings:
  - hedno-vnet-test-prod-gwc-02-to-hedno-hub-germanywest
  - vnetpeer-hedno-vnet-test-prod-gwc-02-to-vnet-ipnet-hub-gwc-01
- DNS Servers: 10.19.66.4, 10.19.66.5
- Route: 0.0.0.0/0 → Virtual Appliance (10.19.64.132)

## Directory Structure

```
rg-test-prod-gwc-02-export/
├── main.bicep                 # Orchestration file
├── main.bicepparam            # Parameter file
├── README.md                  # This file
└── modules/
    ├── vnet.bicep             # Virtual Network with subnets & peerings
    ├── nsg.bicep              # Network Security Group
    ├── routetable.bicep       # Route Table
    ├── nic.bicep              # Network Interface
    ├── disk.bicep             # Managed Disk
    ├── vm.bicep               # Virtual Machine
    ├── vmextensions.bicep     # VM Extensions
    └── dcr.bicep              # Data Collection Rule
```

## Prerequisites

1. **Azure CLI** - Install from https://learn.microsoft.com/cli/azure/install-azure-cli
2. **Bicep CLI** - Ships with Azure CLI or install separately
3. **Azure Subscription Access** - Ensure you have permissions to deploy to target resource group
4. **Existing Log Analytics Workspace** - For monitoring (configured in parameters):
   - Workspace ID: a72a9cdf-95c0-4598-9036-8b1498bfedb0
   - Workspace Resource ID: /subscriptions/f277b017-a5e1-41b7-b016-3ce52c11a68f/resourcegroups/hedno-mgmt-gwc/providers/microsoft.operationalinsights/workspaces/hedno-monitoring-law-gwc

## Deployment

### 1. Validate Template

```bash
az deployment group validate \
  --resource-group rg-test-prod-gwc-02 \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters vmAdminPassword="<SecurePassword>"
```

### 2. Deploy Resources

```bash
az deployment group create \
  --resource-group rg-test-prod-gwc-02 \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters vmAdminPassword="<SecurePassword>"
```

### 3. Using Environment Variables

For security, provide sensitive parameters via environment variables:

```bash
# PowerShell
$vmPassword = Read-Host -AsSecureString "Enter VM Admin Password"
az deployment group create `
  --resource-group rg-test-prod-gwc-02 `
  --template-file main.bicep `
  --parameters main.bicepparam `
  --parameters vmAdminPassword=$vmPassword
```

### 4. Deployment with Custom Parameters

Override specific parameters:

```bash
az deployment group create \
  --resource-group rg-test-prod-gwc-02 \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters \
    vmSize="Standard_B4ms" \
    environment="prod" \
    vmAdminPassword="<SecurePassword>"
```

## Parameters

### Required Parameters
- **vmAdminPassword** (string, secure): Administrator password for Windows VM

### Optional Parameters with Defaults

| Parameter | Default | Description |
|-----------|---------|-------------|
| location | germanywestcentral | Azure region for deployment |
| environment | prod | Environment name for tagging |
| vmName | vmtestprod001 | Virtual Machine name |
| vmSize | Standard_B2as_v2 | VM SKU |
| vmAdminUsername | adminlocal | VM Administrator username |
| computerName | vmtestprod001 | Computer name |
| vnetName | hedno-vnet-test-prod-gwc-02 | Virtual Network name |
| vnetAddressPrefix | 10.19.90.224/28 | VNet address space |
| subnetName | snet-test-prod-gwc-001 | Subnet name |
| subnetAddressPrefix | 10.19.90.224/28 | Subnet CIDR |
| nsgName | nsg-test-prod-gwc-001 | Network Security Group name |
| routeTableName | rt-test-prod-gwc-02 | Route Table name |
| diskName | vmtestprod001_OsDisk_1_c79e16e61dfb47a380bb671e12dcd216 | OS Disk name |
| diskSizeGB | 127 | Disk size in GB |
| dcrName | MSVMI-ama-vmi-default-dcr | Data Collection Rule name |

## Module Details

### vnet.bicep
Deploys Virtual Network with:
- Single subnet (snet-test-prod-gwc-001)
- Two VNet peerings (hub and IPNET)
- Custom DNS servers (10.19.66.4, 10.19.66.5)
- Associated NSG and Route Table to subnet

### nsg.bicep
Deploys Network Security Group with default Azure rules (allow internal, load balancer, internet).

### routetable.bicep
Deploys Route Table with:
- Default route to Virtual Appliance (10.19.64.132)
- Application tags for Expressroute tracking

### nic.bicep
Deploys Network Interface with:
- Dynamic private IP assignment
- Accelerated networking enabled
- Primary IP configuration

### disk.bicep
Deploys Managed Disk with:
- 127GB capacity, StandardSSD_LRS
- Windows OS type
- Zone 1 redundancy
- Platform key encryption

### vm.bicep
Deploys Windows Server 2022 Virtual Machine with:
- System-assigned managed identity
- Automatic patching (AutomaticByPlatform)
- Boot diagnostics enabled
- License type: Windows_Server

### vmextensions.bicep
Deploys three extensions:
1. **AzureMonitorWindowsAgent** - Collects performance metrics
2. **AzurePolicyforWindows** - Applies Azure Policy guest configurations
3. **MDE.Windows** - Microsoft Defender for Servers

### dcr.bicep
Deploys Data Collection Rule for:
- VM Insights performance counters
- Service Map dependency collection
- Connection to Log Analytics Workspace

## Important Notes

1. **VM Admin Password**: The password MUST be provided at deployment time. It is not stored in parameter files for security.

2. **Log Analytics Workspace**: The workspace must exist in subscription f277b017-a5e1-41b7-b016-3ce52c11a68f.

3. **VNet Peerings**: Remote VNets must exist:
   - hedno-hub-germanywest (in different subscription)
   - vnet-ipnet-hub-gwc-01 (in different subscription)

4. **Managed Identity**: VM is created with System-assigned managed identity. Assign appropriate RBAC roles for monitoring.

5. **Zones**: Resources are zone-pinned to Zone 1 for consistency with original configuration.

6. **Tags**: Environment tags are applied to resources for organization and cost tracking.

## Outputs

After successful deployment, the template outputs:

```bicep
- vmId: Resource ID of the created VM
- vmName: Name of the created VM
- vnetId: Resource ID of the Virtual Network
- subnetId: Resource ID of the Subnet
- nicId: Resource ID of the Network Interface
- diskId: Resource ID of the Managed Disk
- dcrId: Resource ID of the Data Collection Rule
- nsgId: Resource ID of the Network Security Group
- routeTableId: Resource ID of the Route Table
```

## Troubleshooting

### Deployment Fails with "Resource Already Exists"
If resources already exist, either:
1. Delete and redeploy, or
2. Use different names in parameters

### VNet Peering Fails
Ensure:
1. Remote VNets exist in their respective subscriptions
2. Service Principal/User has permissions in remote subscriptions
3. Address spaces don't overlap

### Extension Installation Fails
Check:
1. VM launched successfully and agent is running
2. Log Analytics Workspace exists and is accessible
3. VM has network connectivity to workspace

### Monitoring Not Appearing
Allow 5-10 minutes for:
1. Extensions to initialize
2. Data to flow to Log Analytics
3. VM Insights insights to populate

## Cleanup

To remove all deployed resources:

```bash
az deployment group delete \
  --resource-group rg-test-prod-gwc-02 \
  --name main
```

Or delete individual resources:

```bash
az resource delete --ids $(az resource list -g rg-test-prod-gwc-02 --query "[].id" -o tsv)
```

## Additional Resources

- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Virtual Machines](https://learn.microsoft.com/azure/virtual-machines/)
- [VM Insights](https://learn.microsoft.com/azure/azure-monitor/vm/vminsights-overview)
- [VNet Peering](https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
- [Azure Policy Guest Configuration](https://learn.microsoft.com/azure/governance/policy/concepts/guest-configuration)
- [Microsoft Defender for Servers](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-servers-introduction)

---

**Export Date**: April 14, 2026
**Source Subscription**: aa016cda-255f-44aa-9f0e-284417575b2c
**Source Resource Group**: rg-test-prod-gwc-02
**Region**: germanywestcentral
