@description('Globally unique name of the Azure Storage account (3 to 24 lowercase letters and digits). Enter this name in Thisbit.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Object ID of the Thisbit Connector service principal in your tenant, shown on the Thisbit Integrations page.')
param thisbitConnectorObjectId string

@description('Location for the storage account. Defaults to the resource group location.')
param location string = resourceGroup().location

var storageBlobDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    allowBlobPublicAccess: false
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource studioMediaContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobServices
  name: 'studio-media'
  properties: {
    publicAccess: 'None'
  }
}

resource voiceReviewsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobServices
  name: 'voice-reviews'
  properties: {
    publicAccess: 'None'
  }
}

resource connectorBlobRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, thisbitConnectorObjectId, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleId
    principalId: thisbitConnectorObjectId
    principalType: 'ServicePrincipal'
  }
}

output storageAccountName string = storageAccount.name
