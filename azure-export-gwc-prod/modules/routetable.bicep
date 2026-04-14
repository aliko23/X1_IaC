// Route Table Module
// Creates a route table with configurable routes

param location string
param routeTableName string
param tags object = {}
param disableBgpRoutePropagation bool = false

// Routes configuration
param routes array = []

resource routeTable 'Microsoft.Network/routeTables@2023-11-01' = {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: [
      for (route, index) in routes: {
        name: route.name
        properties: {
          addressPrefix: route.addressPrefix
          nextHopType: route.nextHopType
          nextHopIpAddress: route.?nextHopIpAddress ?? ''
        }
      }
    ]
  }
}

output routeTableId string = routeTable.id
output routeTableName string = routeTable.name
