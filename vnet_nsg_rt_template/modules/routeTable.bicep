metadata name = 'Route Table Module'
metadata description = 'Creates a Route Table for subnet routing configuration'

@minLength(1)
@maxLength(80)
@description('Name of the Route Table')
param routeTableName string

@description('Azure region for the Route Table')
param location string

@description('Tags to apply to the Route Table')
param tags object = {}

@description('Disable Border Gateway Protocol (BGP) propagation on the route table')
param disableBgpRoutePropagation bool = false

@description('Array of routes to add to the Route Table')
param routes array = []

resource routeTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    routes: [
      for route in routes: {
        name: route.name
        properties: {
          addressPrefix: route.addressPrefix
          nextHopType: route.nextHopType
          nextHopIpAddress: contains(route, 'nextHopIpAddress') ? route.nextHopIpAddress : null
        }
      }
    ]
    disableBgpRoutePropagation: disableBgpRoutePropagation
  }
}

@description('The resource ID of the Route Table')
output routeTableId string = routeTable.id

@description('The name of the Route Table')
output routeTableName string = routeTable.name
