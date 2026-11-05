@description('Globally unique name of the Azure Storage account (3 to 24 lowercase letters and digits). Enter this name under External location in Thisbit.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Location for the created resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Object ID (principalId) of the Thisbit Connector service principal in your Entra tenant. Find it with: az ad sp show --id aedc1587-9429-480d-a3b3-03d0a34f0251 --query id -o tsv (leave empty to assign Storage Blob Data Contributor in the Azure Portal IAM tab after deployment).')
param thisbitConnectorObjectId string = ''

@description('Storage replication SKU.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageSku string = 'Standard_LRS'

@description('Optional Key Vault name (3 to 24 alphanumeric/hyphens). Leave empty to deploy Storage only.')
param keyVaultName string = ''

// Built-in Azure RBAC role definition IDs
var storageBlobDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var keyVaultSecretsUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSku
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

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = if (!empty(keyVaultName)) {
  name: !empty(keyVaultName) ? keyVaultName : 'kv-placeholder'
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
  }
}

resource connectorKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(keyVaultName) && !empty(thisbitConnectorObjectId)) {
  name: guid(keyVault.id, thisbitConnectorObjectId, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleId
    principalId: thisbitConnectorObjectId
    principalType: 'ServicePrincipal'
  }
}

output thisbitStorageAccount string = storageAccount.name
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
