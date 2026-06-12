// network.bicep
// Virtual network segmented into a public web subnet and a private data subnet,
// each protected by its own NSG with least-privilege rules.

@description('Azure region for all resources')
param location string

@description('Tags applied to all resources')
param tags object

@description('Your current public IP in CIDR form (e.g. 203.0.113.5/32) — used to scope SSH access to just you')
param adminSourceAddressPrefix string

var vnetName = 'vnet-az104-lab'
var webSubnetPrefix = '10.0.1.0/24'
var dataSubnetPrefix = '10.0.2.0/24'

// --- NSG for the public/web tier ---------------------------------------------
resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-web'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        // SSH is locked to your IP only — never open 22 to the Internet.
        name: 'Allow-SSH-From-Admin'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: adminSourceAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

// --- NSG for the private/data tier -------------------------------------------
resource nsgData 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-data'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        // Only the web subnet may reach the data tier (e.g. SQL on 1433).
        name: 'Allow-SQL-From-Web-Subnet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: webSubnetPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '1433'
        }
      }
      {
        name: 'Deny-Internet-Inbound'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// --- Virtual network with both subnets ---------------------------------------
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.0.0.0/16' ]
    }
    subnets: [
      {
        name: 'snet-web'
        properties: {
          addressPrefix: webSubnetPrefix
          networkSecurityGroup: { id: nsgWeb.id }
        }
      }
      {
        name: 'snet-data'
        properties: {
          addressPrefix: dataSubnetPrefix
          networkSecurityGroup: { id: nsgData.id }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output webSubnetId string = vnet.properties.subnets[0].id
output dataSubnetId string = vnet.properties.subnets[1].id
