variable "subscription_id" {
  description = "Azure Subscription ID where the BYOC resources will be provisioned. Leave empty to use ARM_SUBSCRIPTION_ID from the environment."
  type        = string
  default     = ""

  validation {
    condition     = var.subscription_id == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a GUID or empty (when using ARM_SUBSCRIPTION_ID)."
  }
}

variable "tenant_id" {
  description = "Microsoft Entra Tenant ID bound to your Thisbit workspace. Leave empty to use the active az login tenant."
  type        = string
  default     = ""

  validation {
    condition     = var.tenant_id == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "tenant_id must be a GUID or empty."
  }
}

variable "thisbit_connector_client_id" {
  description = "Application (client) ID of the Thisbit Connector for your Thisbit deployment, shown on the Integrations page. Defaults to production Thisbit (aedc1587-9429-480d-a3b3-03d0a34f0251)."
  type        = string
  default     = "aedc1587-9429-480d-a3b3-03d0a34f0251"

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.thisbit_connector_client_id))
    error_message = "thisbit_connector_client_id is the connector's application (client) ID, a GUID."
  }
}

variable "thisbit_account_id" {
  description = "Your Thisbit workspace id (Integrations page). Only used as the thisbit_account_id tag the optional Discover button filters on; empty tags nothing. Connecting the storage account never needs it."
  type        = string
  default     = ""

  validation {
    condition     = var.thisbit_account_id == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.thisbit_account_id))
    error_message = "thisbit_account_id is the workspace id as the Integrations page shows it, a GUID, or empty."
  }
}

variable "resource_group_name" {
  description = "The resource group holding the storage account and Key Vault: created when create_resource_group is true, otherwise an existing one."
  type        = string
  default     = "rg-thisbit-byoc"

  validation {
    condition     = can(regex("^[-\\w.()]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name is 1 to 90 letters, digits, dots, hyphens, underscores or parentheses."
  }
}

variable "create_resource_group" {
  description = "Create resource_group_name (true) or use the existing group by that name (false)."
  type        = bool
  default     = true
}

variable "location" {
  description = "Region of a created resource group; an existing group keeps its own. Thisbit's standard region is EU."
  type        = string
  default     = "westeurope"
}

variable "storage_account_name" {
  description = "Globally unique name of the storage account (3 to 24 lowercase letters and digits): what you enter under External location on the Integrations page."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name is 3 to 24 lowercase letters and digits."
  }
}

variable "storage_replication_type" {
  description = "Replication of the storage account (LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS)."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "storage_replication_type is one of LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS."
  }
}

variable "blob_role_scope" {
  description = "Where the Thisbit Connector gets Storage Blob Data Contributor: the whole storage account (it may then create the two containers when missing) or only its studio-media and voice-reviews containers."
  type        = string
  default     = "account"

  validation {
    condition     = contains(["account", "containers"], var.blob_role_scope)
    error_message = "blob_role_scope is account or containers."
  }
}

variable "create_key_vault" {
  description = "Create a Key Vault (Azure RBAC, purge protection) for tracker and AI model secrets, and grant the connector Key Vault Secrets User on it."
  type        = bool
  default     = true
}

variable "key_vault_name" {
  description = "Globally unique name of the Key Vault; required when create_key_vault is true."
  type        = string
  default     = ""

  validation {
    condition     = var.key_vault_name == "" || can(regex("^[A-Za-z][A-Za-z0-9-]{1,22}[A-Za-z0-9]$", var.key_vault_name))
    error_message = "key_vault_name is 3 to 24 letters, digits and hyphens, starting with a letter."
  }
}

variable "grant_deployer_secrets_officer" {
  description = "Grant the identity applying this configuration Key Vault Secrets Officer on the created vault, so it can put the first secret in."
  type        = bool
  default     = true
}

variable "grant_discovery_reader" {
  description = "Grant the Thisbit Connector Reader on the resource group, which only the optional Discover button on the Integrations page (tagged Key Vaults through Azure Resource Graph) uses."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for every created resource."
  type        = map(string)
  default     = {}
}
