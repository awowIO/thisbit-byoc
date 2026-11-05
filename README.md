# Thisbit BYOC on Azure (`thisbit-byoc-azure`)

Base Terraform configuration to provision the Azure resources a **Corporate (BYOC)** workspace brings for [Thisbit](https://thisbit.ai) in its own Microsoft Entra tenant and Azure subscription.

Clone this repository, drop in your client configuration in `terraform.tfvars` (or wire variables into `variables.tf`), and run `terraform init && terraform apply`.

## What This Provisions

| Resource | Purpose | Protection |
| --- | --- | --- |
| **Resource group** (`azurerm_resource_group.thisbit`, or existing) | Dedicated resource group for Thisbit BYOC resources | `prevent_destroy = true` |
| **Storage account** (`StorageV2`, TLS 1.2, HTTPS only, **shared keys off**, Entra OAuth by default, no public blobs) | Voice walkthrough recordings and Transcript Studio media | `prevent_destroy = true` |
| **Blob containers** (`studio-media` and `voice-reviews`) | Private containers where Thisbit writes audio & transcripts | `prevent_destroy = true` |
| **Key Vault** (Azure RBAC, purge protection, 90-day soft-delete; optional via `create_key_vault`) | Zero-custody tracker and AI model secrets read by URL at request time | `prevent_destroy = true` |
| **Thisbit Connector service principal** (`azuread_service_principal.thisbit_connector`) | The multi-tenant Thisbit Connector identity (`aedc1587-9429-480d-a3b3-03d0a34f0251`) in your tenant | Adopted if existing, created if missing |
| **Data-plane role assignments** | `Storage Blob Data Contributor` on the storage account (or its two containers) and `Key Vault Secrets User` on the vault | Least-privilege data plane only |

Nothing here grants the Thisbit Connector an Azure Resource Manager control-plane role (`Reader` is disabled by default), and no shared storage keys or SAS tokens are enabled. Thisbit claims and verifies the storage account purely over the Azure Blob data plane (`https://<name>.blob.core.windows.net`).

---

## Quickstart

### 1. Clone and configure

```sh
git clone https://github.com/awowIO/thisbit-byoc-azure.git
cd thisbit-byoc-azure
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` (or copy the pre-filled `terraform.tfvars` block directly from [**Integrations → Provision new resources**](https://thisbit.ai/dashboard/integrations.html#key-vault-card)):

```hcl
resource_group_name  = "rg-thisbit-cauchy"
location             = "westeurope"
storage_account_name = "stthisbitcauchy01"
key_vault_name       = "kv-thisbit-cauchy01"
```

*(If you only want the Storage Account for voice reviews and do not need a Key Vault yet, set `create_key_vault = false`.)*

### 2. Sign in to Azure and apply

Sign in to the Microsoft Entra tenant bound to your Thisbit workspace and export the target subscription ID required by `hashicorp/azurerm` v4+:

```sh
az login --tenant <your-entra-tenant-id>
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

terraform init
terraform plan -out byoc.plan
terraform apply byoc.plan
```

> **Permissions required to apply:**
> - `Owner` or `Contributor` + `User Access Administrator` on the Azure subscription (or target resource group when `create_resource_group = false`) to create the resources and RBAC role assignments.
> - Entra `Application Administrator` or `Cloud Application Administrator` if the Thisbit Connector service principal does not yet exist in your tenant (if your workspace already connected Entra SSO on `thisbit.ai`, the service principal may already exist and will be adopted via `use_existing = true`).

### 3. Connect the storage account in Thisbit

Copy the storage account name from the Terraform output:

```sh
terraform output -raw thisbit_storage_account
```

Open [**Thisbit → Integrations → External location**](https://thisbit.ai/dashboard/integrations.html#key-vault-card), paste the storage account name (or its `https://<name>.blob.core.windows.net` endpoint), and click **Connect storage account**.

Thisbit verifies data-plane access as the Thisbit Connector in your tenant, writes `.thisbit-workspace` into `voice-reviews/` and `studio-media/`, and routes voice walkthrough recordings directly into your storage account.

---

## Configuration Options (`variables.tf`)

| Variable | Default | Description |
| --- | --- | --- |
| `subscription_id` | `""` | Azure Subscription ID (or set `ARM_SUBSCRIPTION_ID` in your shell) |
| `tenant_id` | `""` | Microsoft Entra Tenant ID (or use the active `az login` tenant) |
| `thisbit_connector_client_id` | `"aedc1587-9429-480d-a3b3-03d0a34f0251"` | Production Thisbit Connector application (client) ID |
| `resource_group_name` | `"rg-thisbit-byoc"` | Name of the resource group to create or use |
| `create_resource_group` | `true` | Set `false` to deploy into an existing resource group |
| `location` | `"westeurope"` | Azure region for new resources |
| `storage_account_name` | *(required)* | Globally unique storage account name (`3–24` lowercase letters/digits) |
| `storage_replication_type` | `"LRS"` | Storage replication (`LRS`, `ZRS`, `GRS`, `RAGRS`, `GZRS`, `RAGZRS`) |
| `blob_role_scope` | `"account"` | `"account"` (whole storage account) or `"containers"` (`studio-media` and `voice-reviews` only) |
| `create_key_vault` | `true` | Set `false` to provision only the Storage Account |
| `key_vault_name` | `""` | Globally unique Key Vault name (`3–24` alphanumeric/hyphens; required when `create_key_vault = true`) |
| `grant_deployer_secrets_officer` | `true` | Grant the identity running Terraform `Key Vault Secrets Officer` on the vault |
| `thisbit_account_id` | `""` | Optional Thisbit workspace ID tag (only used by the optional **Discover** button) |
| `grant_discovery_reader` | `false` | Optional `Reader` role on the resource group (only used by the optional **Discover** button) |
| `tags` | `{}` | Additional tags applied to created resources |

---

## Destruction Protection (`prevent_destroy = true`)

Every stateful resource (`azurerm_resource_group`, `azurerm_storage_account`, `azurerm_storage_container`, `azurerm_key_vault`) is guarded with:

```hcl
lifecycle {
  prevent_destroy = true
}
```

Any `terraform destroy` or plan that would replace the storage account or Key Vault will refuse to run so recordings and secrets cannot be accidentally wiped.
