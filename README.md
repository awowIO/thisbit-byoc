# Thisbit BYOC on Azure (`thisbit-byoc-azure`)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FawowIO%2Fthisbit-byoc-azure%2Fmain%2Fazuredeploy.json)

Provision the Azure resources a **Corporate (BYOC)** workspace brings for [Thisbit](https://thisbit.ai) in its own Microsoft Entra tenant and Azure subscription—either in **1 click via the Azure Portal** (`azuredeploy.json` / `azuredeploy.bicep`) or with **Terraform** (`main.tf`).

> Prefer AWS S3, Cloudflare R2, Hetzner Object Storage, or MinIO instead of Azure? See **[`awowIO/thisbit-byoc-s3`](https://github.com/awowIO/thisbit-byoc-s3)**.

---

## Option A: 1-Click "Deploy to Azure" (Browser Only, Zero CLI)

Click **[Deploy to Azure ↗](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FawowIO%2Fthisbit-byoc-azure%2Fmain%2Fazuredeploy.json)** to open the Azure Portal template deployment form directly in your browser:

1. Select your **Subscription** and **Resource group** (or click *Create new*).
2. Enter a globally unique **Storage Account Name** (e.g. `stthisbitcauchy01`).
3. *(Optional)* Enter the **Thisbit Connector Object ID** in your tenant to grant `Storage Blob Data Contributor` automatically, or assign `Storage Blob Data Contributor` to **Thisbit Connector** in the storage account's **Access Control (IAM)** tab after creation.
4. Enter the storage account name under [**Thisbit → Integrations → External location**](https://thisbit.ai/dashboard/integrations.html#key-vault-card) and click **Connect storage account**.

---

## Option B: Drop into an Existing Terraform Repo (5-Line Module)

If you already manage Azure with Terraform, reference this repository directly as a module:

```hcl
module "thisbit_byoc" {
  source               = "github.com/awowIO/thisbit-byoc-azure"
  resource_group_name  = "rg-thisbit-cauchy"
  storage_account_name = "stthisbitcauchy01"
  location             = "westeurope"
}
```

---

## Option C: Standalone Clone & Apply

### 1. Clone and configure `terraform.tfvars`

```sh
git clone https://github.com/awowIO/thisbit-byoc-azure.git
cd thisbit-byoc-azure
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
resource_group_name  = "rg-thisbit-cauchy"
storage_account_name = "stthisbitcauchy01"
location             = "westeurope"
```

### 2. Sign in to Azure and apply

```sh
az login --tenant <your-entra-tenant-id>
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

terraform init
terraform apply
```

### 3. Connect the storage account in Thisbit

Enter `terraform output -raw thisbit_storage_account` under [**Thisbit → Integrations → External location**](https://thisbit.ai/dashboard/integrations.html#key-vault-card) and click **Connect storage account**.
