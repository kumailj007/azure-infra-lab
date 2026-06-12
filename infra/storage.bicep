// storage.bicep
// A StorageV2 account configured securely: HTTPS-only, TLS 1.2 minimum, public
// blob access disabled, plus a single private container.

@description('Azure region')
param location string

@description('Tags applied to all resources')
param tags object

@description('Globally-unique storage account name (3-24 chars, lowercase letters and numbers only)')
@minLength(3)
@maxLength(24)
param storageAccountName string

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'app-data'
  properties: {
    publicAccess: 'None'
  }
}

output storageAccountName string = storage.name
