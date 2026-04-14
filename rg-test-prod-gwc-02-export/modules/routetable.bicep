// Route Table Module
// Exports: rt-test-prod-gwc-02

param location string
param routeTableName string
param routes array = []
param disableBgpRoutePropagation bool = false
param environment string = 'prod'
param customTags object = {}

resource routeTable 'Microsoft.Network/routeTables@2023-11-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: routes
  }
  tags: union({
    environment: environment
  }, customTags)
}

output routeTableId string = routeTable.id
output routeTableName string = routeTable.name
