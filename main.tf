# Thisbit Corporate (BYOC): the Azure resources a workspace brings for Thisbit, in its own tenant.
#
# Repository: https://github.com/awowIO/thisbit-byoc-azure
# Docs:       https://thisbit.ai/docs/#data-flow
#
# Provisions:
# - A dedicated Resource Group (or adopts an existing one when create_resource_group = false)
# - An Azure Storage account for voice walkthrough recordings and Transcript Studio media
#   (`studio-media` and `voice-reviews` containers, shared keys disabled, Entra OAuth only)
# - An optional Azure Key Vault (Azure RBAC, purge protection) for tracker and AI model secrets
# - The Thisbit Connector service principal in your Entra tenant
# - Data-plane-only role assignments (`Storage Blob Data Contributor`, `Key Vault Secrets User`)
#
# Every data-holding resource carries `prevent_destroy = true`: a plan that would remove it fails
# instead of destroying recordings or secrets.

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
  tenant_id       = var.tenant_id != "" ? var.tenant_id : null

  features {
    key_vault {
      # Purge protection is on below; the provider never tries to purge a vault it destroyed.
      purge_soft_delete_on_destroy = false
    }
  }
  # The storage account disables shared keys, so the provider's own data-plane calls use Entra as well.
  storage_use_azuread = true
}

provider "azuread" {
  tenant_id = var.tenant_id != "" ? var.tenant_id : null
}

data "azurerm_client_config" "current" {}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.thisbit[0].name : data.azurerm_resource_group.existing[0].name
  resource_group_id   = var.create_resource_group ? azurerm_resource_group.thisbit[0].id : data.azurerm_resource_group.existing[0].id
  location            = var.create_resource_group ? azurerm_resource_group.thisbit[0].location : data.azurerm_resource_group.existing[0].location
  containers          = toset(["studio-media", "voice-reviews"])
  create_key_vault    = var.create_key_vault && var.key_vault_name != ""
  # The thisbit_account_id tag is only what the optional Discover button on the Integrations page filters on.
  tags = var.thisbit_account_id == "" ? var.tags : merge(var.tags, { thisbit_account_id = var.thisbit_account_id })
}

# --- resource group: created here, or an existing one ------------------------------------------------------

resource "azurerm_resource_group" "thisbit" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

# --- the Thisbit Connector in this tenant --------------------------------------------------------------------

# The multi-tenant Thisbit Connector application, as a service principal in this tenant (created when it is not
# there yet). Its roles below are the only access Thisbit has in this subscription.
resource "azuread_service_principal" "thisbit_connector" {
  client_id    = var.thisbit_connector_client_id
  use_existing = true
}

# --- storage: voice walkthrough recordings and Transcript Studio media ---------------------------------------

resource "azurerm_storage_account" "thisbit" {
  name                            = var.storage_account_name
  resource_group_name             = local.resource_group_name
  location                        = local.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = var.storage_replication_type
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  tags                            = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "thisbit" {
  for_each              = local.containers
  name                  = each.key
  storage_account_id    = azurerm_storage_account.thisbit.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

# Data plane only: the connector reads and writes blobs, and learns nothing about the account itself. On the
# account, it may also create the two containers when they are missing; on the containers, they must exist.
resource "azurerm_role_assignment" "connector_blob_data_account" {
  count                = var.blob_role_scope == "account" ? 1 : 0
  scope                = azurerm_storage_account.thisbit.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.thisbit_connector.object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "connector_blob_data_container" {
  for_each             = var.blob_role_scope == "containers" ? local.containers : toset([])
  scope                = azurerm_storage_container.thisbit[each.key].resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.thisbit_connector.object_id
  principal_type       = "ServicePrincipal"
}

# --- Key Vault: optional tracker and AI model secrets, read by URL at use time -----------------------------------

resource "azurerm_key_vault" "thisbit" {
  count                      = local.create_key_vault ? 1 : 0
  name                       = var.key_vault_name
  resource_group_name        = local.resource_group_name
  location                   = local.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 90 # Azure's default and maximum
  tags                       = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "connector_secrets" {
  count                = local.create_key_vault ? 1 : 0
  scope                = azurerm_key_vault.thisbit[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.thisbit_connector.object_id
  principal_type       = "ServicePrincipal"
}

# The identity applying this may put secrets in, so the first secret needs no second step.
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  count                = local.create_key_vault && var.grant_deployer_secrets_officer ? 1 : 0
  scope                = azurerm_key_vault.thisbit[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# --- optional: discovery through Azure Resource Graph -------------------------------------------------------------

# Only for the Discover button on the Integrations page, which lists the tagged Key Vault and its tagged secrets.
# Connecting the storage account never needs it.
resource "azurerm_role_assignment" "connector_reader" {
  count                = var.grant_discovery_reader ? 1 : 0
  scope                = local.resource_group_id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.thisbit_connector.object_id
  principal_type       = "ServicePrincipal"
}
