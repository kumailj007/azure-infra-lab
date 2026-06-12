// main.bicep
// Orchestrates the lab: a segmented VNet, a web-tier VM, and a secure storage
// account — all tagged consistently and deployed at resource-group scope.

targetScope = 'resourceGroup'

@description('Azure region for all resources (defaults to the resource group region)')
param location string = resourceGroup().location

@description('Your current public IP in CIDR form for SSH access, e.g. 203.0.113.5/32')
param adminSourceAddressPrefix string

@description('VM admin username')
param adminUsername string = 'azureadmin'

@description('SSH public key for the VM admin user (contents of your .pub file)')
param adminSshPublicKey string

@description('Globally-unique storage account name (3-24 lowercase alphanumerics)')
param storageAccountName string

var tags = {
  project: 'az104-infra-lab'
  environment: 'lab'
  managedBy: 'bicep'
}

module network 'network.bicep' = {
  name: 'network-deployment'
  params: {
    location: location
    tags: tags
    adminSourceAddressPrefix: adminSourceAddressPrefix
  }
}

module compute 'compute.bicep' = {
  name: 'compute-deployment'
  params: {
    location: location
    tags: tags
    webSubnetId: network.outputs.webSubnetId
    adminUsername: adminUsername
    adminSshPublicKey: adminSshPublicKey
  }
}

module storage 'storage.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location
    tags: tags
    storageAccountName: storageAccountName
  }
}

output webServerPublicIp string = compute.outputs.publicIpAddress
output webServerUrl string = 'http://${compute.outputs.publicIpAddress}'
output storageAccount string = storage.outputs.storageAccountName
