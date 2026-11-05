output "thisbit_storage_account" {
  description = "Enter this under External location on the Integrations page to record voice walkthroughs into it."
  value       = azurerm_storage_account.thisbit.name
}

output "blob_endpoint" {
  description = "The storage account's Blob endpoint; the Integrations page accepts this address too."
  value       = azurerm_storage_account.thisbit.primary_blob_endpoint
}

output "containers" {
  description = "The containers Thisbit records into."
  value       = sort([for container in azurerm_storage_container.thisbit : container.name])
}

output "key_vault_uri" {
  description = "The Key Vault's URI; a secret's URL is <uri>secrets/<name>. Null when no vault was created."
  value       = var.create_key_vault ? azurerm_key_vault.thisbit[0].vault_uri : null
}

output "thisbit_connector_object_id" {
  description = "Object id of the Thisbit Connector's service principal in this tenant, the principal every role here is granted to."
  value       = azuread_service_principal.thisbit_connector.object_id
}

output "resource_group_name" {
  description = "The resource group holding everything above."
  value       = local.resource_group_name
}
