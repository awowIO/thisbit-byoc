variable "storage_account_name" { type = string }
variable "resource_group_name" { default = "rg-thisbit" }
variable "location" { default = "westeurope" }
variable "create_resource_group" { default = true }

# Global multi-tenant Thisbit Connector app ID (resolved in your tenant automatically unless object_id is set).
variable "thisbit_connector_client_id" { default = "aedc1587-9429-480d-a3b3-03d0a34f0251" }
variable "thisbit_connector_object_id" {
  type    = string
  default = null
}

resource "azurerm_resource_group" "thisbit" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
}

data "azurerm_resource_group" "thisbit" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

resource "azuread_service_principal" "thisbit" {
  count        = var.thisbit_connector_object_id == null ? 1 : 0
  client_id    = var.thisbit_connector_client_id
  use_existing = true
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.thisbit[0].name : data.azurerm_resource_group.thisbit[0].name
  location            = var.create_resource_group ? azurerm_resource_group.thisbit[0].location : data.azurerm_resource_group.thisbit[0].location
  tags                = var.create_resource_group ? {} : data.azurerm_resource_group.thisbit[0].tags
  connector_object_id = coalesce(var.thisbit_connector_object_id, try(azuread_service_principal.thisbit[0].object_id, null))
}

resource "azurerm_storage_account" "thisbit" {
  name                            = var.storage_account_name
  resource_group_name             = local.resource_group_name
  location                        = local.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  tags                            = local.tags
  lifecycle { prevent_destroy = true }
}

resource "azurerm_storage_container" "thisbit" {
  for_each              = toset(["studio-media", "voice-reviews"])
  name                  = each.key
  storage_account_id    = azurerm_storage_account.thisbit.id
  container_access_type = "private"
  lifecycle { prevent_destroy = true }
}

resource "azurerm_role_assignment" "thisbit" {
  scope                = azurerm_storage_account.thisbit.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.connector_object_id
  principal_type       = "ServicePrincipal"
}

output "storage_account_name" { value = azurerm_storage_account.thisbit.name }
output "thisbit_connector_object_id" { value = local.connector_object_id }
