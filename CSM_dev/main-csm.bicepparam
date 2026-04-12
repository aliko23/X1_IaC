using 'main-csm.bicep'

param workloadName = 'csm'
param env = 'qa'

param rgName = 'rg-csm-qa-gwc-01'

// param lawName = 'hedno-sentinel-law-gwc'

// param rgLawName = 'hedno-mgmt-sec-gwc'


param  vnetConfiguration = {
  vnetName: 'hedno-vnet-csm-qa-gwc-01'
  subnets: [
    {
      name: 'snet-csm-qa-gwc-02' 
    } 
  ]
}
