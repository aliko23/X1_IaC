
@description('The APIM settings type')
@export()
type apimSettingsType = {
  @description('The name of the owner of APIM')
  @minLength(1)
  publisherName: string
  
  @description('The email address of the owner of APIM')
  @minLength(1)  
  publisherEmail: string

  @description('The pricing tier of this APIM')
  sku: string?
   
  @description('The subnet ID of the vnet the APIM is deployed on')
  subnetId : string?
  
  @description('The vnet type of the APIM')
  vnetType : string?
}


@description('The vnet subnet type')
@export()
type vnetSubnetType = {
  @description('The Name of the Subnet')
  @minLength(8)  
  name : string

  @description('The ID of the Subnet')
  id: string?
  
  @description('The AddressPrefix of the Subnet')
  addressPrefix : string
  
  @description('The NSG associated with the Subnet')
  networkSecurityGroup : string?
  
  @description('the route table associated with the subnet')
  routeTable : string?
  
  @description('the delegation of the subnet')
  delegation: string?
}

@description('The VNet settings type')
@export()
type vnetSettingsType  = {
  @description('The Name of the VNet')
  name : string?
  
  @description('The Address Space Used for VNet')
  addressSpace : string
  
  @description('The Subnets of the VNet')
  subnets: vnetSubnetType[]
}


@description('The index of the resource')
@minValue(1)
@maxValue(99)
type indexType = int


@description('This type is only required to set the min length, so that you can avoid the warning bicepBCP334. Example:  __"The provided value can have a length as small as x and may be too short to assign to a target with a configured minimum length of 2.bicepBCP334__')
@minLength(3)
@export()
type nonEmptyStringType = string


@description('The regions, used in the naming scheme')
var regions = loadJsonContent('../_configuration/azure_regions.json')


@description('The function to generate a name based on resource identifier, workload name, environment, location, and index')
@export()
func getName(
  resourceIdentifier string,
  workloadName string,
  env string,
  locationShortName string,
  index indexType?
) nonEmptyStringType => '${resourceIdentifier}-${workloadName}-${env}-${regions[locationShortName].shortName}${index == null  ? '' : '-${padLeft(string(index), 2, '0')}'}'


@description('The function to generate a name based on resource identifier, workload name, environment, location, and index')
@export()
func getUniqueName(
  resourceIdentifier string,
  workloadName string,
  env string,
  locationShortName string,
  resourceGroupId string,
  index indexType?
) nonEmptyStringType => '${resourceIdentifier}-${take(workloadName, 8)}-${env}-${regions[locationShortName].shortName}-${take(uniqueString(resourceGroupId), 5)}${index == null  ? '' : '-${padLeft(string(index), 2, '0')}'}'


@description('takeSafe: Similar to take function but if the last character is not a letter or number, it will be removed')
@export()
func takeSafe(
  str string,
  length int
) nonEmptyStringType => endsWith(take(str, length), '-') || endsWith(take(str, length), '_') || endsWith(take(str, length),  '.') ? substring(take(str, length), 0, length - 1) : take(str, length)
