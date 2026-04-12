# Virtual Network with Subnets, NSGs, and Route Tables - Bicep Template

This is a production-ready, modular Bicep template that deploys:
- **1 Virtual Network (VNet)** with configurable address space
- **3 Subnets** with individual configurations
- **3 Network Security Groups (NSGs)** - one per subnet with default security rules
- **3 Route Tables** - one per subnet for custom routing

## Template Structure

```
vnet_nsg_rt_template/
├── main.bicep              # Main orchestration template
├── main.bicepparam         # Parameter file with deployment values
├── modules/
│   ├── vnet.bicep          # Virtual Network module
│   ├── nsg.bicep           # Network Security Group module
│   └── routeTable.bicep    # Route Table module
└── README.md               # This file
```

## Key Features

✅ **Modular Design** - Separate modules for VNet, NSG, and Route Tables for reusability
✅ **Three Subnets** - Pre-configured with realistic naming conventions
✅ **Automated NSG Association** - Each subnet automatically associated with its NSG
✅ **Automated Route Table Association** - Each subnet linked to its Route Table
✅ **Security Best Practices** - Default NSG rules follow Azure security guidelines
✅ **Parameterized** - Fully configurable via .bicepparam file
✅ **Azure Naming Conventions** - Follows Microsoft naming recommendations
✅ **Strong Typing** - Uses Bicep decorators for validation

## Default Configuration

| Resource | Count | Details |
|----------|-------|---------|
| Virtual Network | 1 | 10.0.0.0/16 |
| Subnets | 3 | Web, App, Database |
| NSGs | 3 | One per subnet |
| Route Tables | 3 | One per subnet |

### Default Subnets

1. **snet-web-prod-01** (10.0.1.0/24) - Web tier
2. **snet-app-prod-01** (10.0.2.0/24) - Application tier
3. **snet-db-prod-01** (10.0.3.0/24) - Database tier

### Default NSG Rules

**Inbound:**
- Allow VNet-to-VNet traffic
- Allow Azure Load Balancer health checks
- Deny all other inbound traffic

**Outbound:**
- Allow VNet-to-VNet traffic
- Allow outbound to Internet
- Implicit allow for other outbound

## Deployment

### Prerequisites
- Azure CLI or Azure PowerShell
- Appropriate permissions on the target subscription
- Bicep CLI (included with Azure CLI v2.3.0+)

### Deploy via Azure CLI

```bash
# Validate the template
az deployment group validate \
  --resource-group rg-test-prod-gwc-01 \
  --template-file main.bicep \
  --parameters @main.bicepparam

# Deploy
az deployment group create \
  --resource-group rg-test-prod-gwc-01 \
  --template-file main.bicep \
  --parameters @main.bicepparam
```

### Deploy via Azure PowerShell

```powershell
# Validate the template
Test-AzResourceGroupDeployment `
  -ResourceGroupName "rg-test-prod-gwc-01" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "main.bicepparam"

# Deploy
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-test-prod-gwc-01" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "main.bicepparam"
```

## Customization

### Modify Subnets

Edit `main.bicepparam` to change subnet configurations:

```bicepparam
param subnets = [
  {
    name: 'snet-custom-01'
    addressPrefix: '10.0.1.0/24'
    nsgName: 'nsg-custom-01'
    rtName: 'rt-custom-01'
  }
  // Add more subnets as needed
]
```

### Add Routes to Route Tables

Update route table configuration in `main.bicep` by passing routes parameter:

```bicep
module routeTables 'modules/routeTable.bicep' = [
  for (subnet, index) in subnets: {
    params: {
      // ... existing params
      routes: [
        {
          name: 'route-to-firewall'
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.0.1'
        }
      ]
    }
  }
]
```

### Customize NSG Rules

Modify security rules in `modules/nsg.bicep` or pass custom rules via parameters:

```bicep
param securityRules = [
  {
    name: 'AllowHTTP'
    priority: 200
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '80'
    sourceAddressPrefix: 'Internet'
    destinationAddressPrefix: '*'
  }
  // Add more rules
]
```

## Outputs

The template outputs the following information after deployment:

| Output | Description |
|--------|-------------|
| `vnetId` | Resource ID of the Virtual Network |
| `vnetName` | Name of the Virtual Network |
| `subnetIds` | Array of all subnet IDs |
| `nsgIds` | Array of all NSG IDs |
| `routeTableIds` | Array of all Route Table IDs |

## Security Considerations

- **NSG Rules** - Default rules deny all inbound traffic except from VNet and Load Balancer. Customize based on workload requirements.
- **Route Tables** - Initially empty. Add custom routes for traffic routing through firewalls or NVAs as needed.
- **Encryption** - Virtual networks don't have built-in encryption. Use NSGs, Network Security Groups, or Azure Firewall for additional security.
- **DDoS Protection** - Can be enabled via the `enableDdosProtection` parameter (requires Azure DDoS Protection Standard SKU).

## Cost Optimization

- **Virtual Networks** - No direct charge; costs are based on data transfer
- **NSGs** - 5 NSGs included in subscription cost; additional NSGs are $0.50/month each
- **Route Tables** - $0.05/month for the first 10 route tables
- Monitor usage and consolidate NSGs/Route Tables where possible

## Troubleshooting

### Template Validation Fails
- Ensure all subnet address prefixes fall within the VNet address space
- Verify address prefixes don't overlap
- Check resource names follow Azure naming rules (alphanumeric, hyphens only)

### Deployment Fails
- Verify the resource group exists: `az group list | grep rg-test-prod-gwc-01`
- Check RBAC permissions on the resource group
- Review deployment error details: `az deployment group show --resource-group rg-test-prod-gwc-01 --name <deployment-name>`

### Resources Not Associated
- If subnets aren't associated with NSGs/Route Tables, verify the IDs are passed correctly
- Check subnet properties: `az network vnet subnet show --resource-group <rg> --vnet-name <vnet> --name <subnet>`

## Next Steps

1. **Add NSG Rules** - Customize inbound/outbound rules for your workloads
2. **Configure Routes** - Add custom routes to route tables for traffic management
3. **Enable Monitoring** - Set up Azure Monitor for VNet flow logs
4. **Implement DDoS** - Enable DDoS Standard protection if required
5. **Add VNet Peering** - Connect to other virtual networks as needed

## Related Templates

- Private Endpoint Module
- Firewall Configuration
- VNet Peering Setup
- Network Watcher Configuration

## Support

For issues or questions:
1. Review Azure Bicep documentation: https://learn.microsoft.com/azure/azure-resource-manager/bicep/
2. Check Azure Virtual Network docs: https://learn.microsoft.com/azure/virtual-network/
3. Validate templates with: `az bicep validate --file main.bicep`

---

**Template Version:** 1.0
**Last Updated:** 2026-04-11
**Bicep Target:** 0.26.0+
