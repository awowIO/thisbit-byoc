variable "storage_account_name" { type = string }
variable "thisbit_connector_object_id" { type = string }
variable "resource_group_name" { default = "rg-thisbit" }
variable "location" { default = "westeurope" }

resource "azurerm_resource_group" "thisbit" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "thisbit" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.thisbit.name
  location                        = azurerm_resource_group.thisbit.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  lifecycle { prevent_destroy = true }
}

resource "azurerm_storage_container" "thisbit" {
  for_each           = toset(["studio-media", "voice-reviews"])
  name               = each.key
  storage_account_id = azurerm_storage_account.thisbit.id
  lifecycle { prevent_destroy = true }
}

resource "azurerm_role_assignment" "thisbit" {
  scope                = azurerm_storage_account.thisbit.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.thisbit_connector_object_id
  principal_type       = "ServicePrincipal"
}

output "storage_account_name" { value = azurerm_storage_account.thisbit.name }
