# Thisbit BYOC (`thisbit-byoc`)

Thisbit records into `studio-media/` and `voice-reviews/` and reserves the store for one workspace with `voice-reviews/.thisbit-workspace`. Use a store dedicated to Thisbit.

| | **Azure Blob / ADLS** ([`azure/`](azure/)) | **S3 protocol** ([`s3/`](s3/) — AWS, R2, Hetzner, Scaleway, Spaces, B2, Wasabi, MinIO, Garage, Ceph) |
| --- | --- | --- |
| **You create** | a storage account | a bucket |
| **You grant** | `Storage Blob Data Contributor` → **Thisbit Connector** (object ID shown in Thisbit) | an access key: `GetObject`, `PutObject`, `DeleteObject` on the bucket (narrow to the two prefixes if your provider can) |
| **You paste in Thisbit** | account name | endpoint, bucket, key ID, secret |
| **Thisbit stores** | nothing secret (Entra) | the key, encrypted |
| **Fastest** | [Deploy to Azure ↗](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FawowIO%2Fthisbit-byoc%2Fmain%2Fazure%2Fazuredeploy.json) | provider console: bucket + key |
| **IaC** | [`azure/`](azure/) | [`s3/aws/`](s3/aws/), [`s3/cloudflare-r2/`](s3/cloudflare-r2/) |

S3 providers must support HTTPS, path-style requests, and conditional PUT (`If-None-Match: *`).
