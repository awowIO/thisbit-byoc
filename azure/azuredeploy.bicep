@description('Globally unique name of the Azure Storage account (3 to 24 lowercase letters and digits). Enter this name in Thisbit.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Optional: Object ID of the Thisbit Connector enterprise app in your tenant (run: az ad sp create --id aedc1587-9429-480d-a3b3-03d0a34f0251 --query id -o tsv). Leave blank to assign Storage Blob Data Contributor to "Thisbit Connector" in the Portal IAM tab after deployment.')
param thisbitConnectorObjectId string = ''

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

resource connectorBlobRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(thisbitConnectorObjectId)) {
  name: guid(storageAccount.id, thisbitConnectorObjectId, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleId
    principalId: thisbitConnectorObjectId
    principalType: 'ServicePrincipal'
  }
}

output storageAccountName string = storageAccount.name
