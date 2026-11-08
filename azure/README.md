# Azure Blob / ADLS (`azure/`)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FawowIO%2Fthisbit-byoc%2Fmain%2Fazure%2Fazuredeploy.json)

Once your Microsoft Entra tenant is connected in Thisbit, **Thisbit Connector** (`aedc1587-9429-480d-a3b3-03d0a34f0251`) is registered as an Enterprise Application in your tenant automatically.

## 1. Fastest: Deploy to Azure

1. Click **[Deploy to Azure ↗](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FawowIO%2Fthisbit-byoc%2Fmain%2Fazure%2Fazuredeploy.json)** and enter a storage account name.
2. Either paste your tenant's **Thisbit Connector** object ID (`az ad sp create --id aedc1587-9429-480d-a3b3-03d0a34f0251 --query id -o tsv`), or leave it blank and grant **Storage Blob Data Contributor** to **Thisbit Connector** in the storage account's **Access Control (IAM)** tab after deployment.
3. Paste the storage account name into **Thisbit → Integrations → Azure Blob** and click **Connect**.

## 2. Terraform (`main.tf`)

[`main.tf`](main.tf) resolves **Thisbit Connector** (`aedc1587-9429-480d-a3b3-03d0a34f0251`) in your tenant automatically:

```sh
az login --tenant <your-tenant-id>
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

terraform init
terraform apply -var="storage_account_name=stthisbit01"
```

Deploying into a pre-vended landing-zone resource group (or a CI pipeline without Microsoft Graph permissions):

```sh
terraform apply \
  -var="storage_account_name=stthisbit01" \
  -var="resource_group_name=rg-existing" \
  -var="create_resource_group=false" \
  -var="thisbit_connector_object_id=<sp-object-id-in-your-tenant>"
```

## 3. Existing storage account (1 CLI line)

```sh
az role assignment create \
  --assignee aedc1587-9429-480d-a3b3-03d0a34f0251 \
  --role "Storage Blob Data Contributor" \
  --scope "$(az storage account show --name <storage-account> --query id -o tsv)"
```
