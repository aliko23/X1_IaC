metadata name = 'Virtual Network with Subnets, NSGs, and Route Tables'
metadata description = 'Deploys a virtual network with three subnets, each with associated Network Security Groups and Route Tables'
metadata author = 'Generated Bicep Template'

@minLength(1)
@maxLength(64)
@description('Name of the virtual network')
param vnetName string

@minLength(1)
@maxLength(64)
@description('Name of the resource group')
param resourceGroupName string = resourceGroup().name

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@minLength(1)
@maxLength(18)
@description('Address space for the virtual network (CIDR notation)')
param vnetAddressSpace string = '10.0.0.0/16'

@description('Array of subnet configurations')
param subnets array = [
  {
    name: 'subnet-01'
    addressPrefix: '10.0.1.0/24'
    nsgName: 'nsg-subnet-01'
    rtName: 'rt-subnet-01'
  }
  {
    name: 'subnet-02'
    addressPrefix: '10.0.2.0/24'
    nsgName: 'nsg-subnet-02'
    rtName: 'rt-subnet-02'
  }
  {
    name: 'subnet-03'
    addressPrefix: '10.0.3.0/24'
    nsgName: 'nsg-subnet-03'
    rtName: 'rt-subnet-03'
  }
]

@description('Tags to apply to all resources')
param tags object = {
  environment: 'production'
  createdBy: 'bicep'
  createdDate: utcNow('yyyy-MM-dd')
}

// Create Network Security Groups
module nsgs 'modules/nsg.bicep' = [
  for (subnet, index) in subnets: {
    name: 'nsg-${subnet.name}-${uniqueString(resourceGroup().id)}'
    params: {
      location: location
      nsgName: subnet.nsgName
      tags: tags
    }
  }
]

// Create Route Tables
module routeTables 'modules/routeTable.bicep' = [
  for (subnet, index) in subnets: {
    name: 'rt-${subnet.name}-${uniqueString(resourceGroup().id)}'
    params: {
      location: location
      routeTableName: subnet.rtName
      tags: tags
    }
  }
]

// Create Virtual Network with Subnets
module vnet 'modules/vnet.bicep' = {
  name: 'vnet-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    vnetName: vnetName
    addressSpace: vnetAddressSpace
    subnets: [
      for (subnet, index) in subnets: {
        name: subnet.name
        addressPrefix: subnet.addressPrefix
        nsgId: nsgs[index].outputs.nsgId
        routeTableId: routeTables[index].outputs.routeTableId
      }
    ]
    tags: tags
  }
}

@description('Virtual Network ID')
output vnetId string = vnet.outputs.vnetId

@description('Virtual Network Name')
output vnetName string = vnet.outputs.vnetName

@description('Subnet IDs')
output subnetIds array = vnet.outputs.subnetIds

@description('NSG IDs')
output nsgIds array = [
  for index in range(0, length(subnets)): nsgs[index].outputs.nsgId
]

@description('Route Table IDs')
output routeTableIds array = [
  for index in range(0, length(subnets)): routeTables[index].outputs.routeTableId
]
