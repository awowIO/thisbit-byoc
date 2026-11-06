# Azure Blob / ADLS (`azure/`)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FawowIO%2Fthisbit-byoc%2Fmain%2Fazure%2Fazuredeploy.json)

## 1. Fastest: Deploy to Azure

1. Copy the **Thisbit Connector object ID** shown on [Thisbit → Integrations](https://thisbit.ai/dashboard/integrations.html#key-vault-card).
2. Click **[Deploy to Azure ↗](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FawowIO%2Fthisbit-byoc%2Fmain%2Fazure%2Fazuredeploy.json)**, enter a storage account name and that object ID, and click **Review + create**.
3. Paste the storage account name into **Thisbit → Integrations → Azure Blob** and click **Connect**.

## 2. Terraform (`main.tf`)

Copy [`main.tf`](main.tf) into your Terraform repo (or run standalone in this directory alongside [`providers.tf`](providers.tf)):

```sh
az login --tenant <your-tenant-id>
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

terraform init
terraform apply \
  -var="storage_account_name=stthisbitcauchy01" \
  -var="thisbit_connector_object_id=<object-id-from-thisbit>"
```

## 3. Existing storage account (1 CLI line)

```sh
az role assignment create \
  --assignee-object-id <object-id-from-thisbit> \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$(az storage account show --name <storage-account> --query id -o tsv)"
```
