# S3-Compatible Storage (`s3/`)

Thisbit speaks standard S3 (`AWS4-HMAC-SHA256`, HTTPS, path-style requests, and `If-None-Match: *` conditional PUT).

## The Protocol Contract

1. **Create a dedicated bucket** for your Thisbit workspace.
2. **Create an access key** with `GetObject`, `PutObject`, and `DeleteObject` on that bucket (scoped to `studio-media/*` and `voice-reviews/*` if your provider supports prefix policies).
3. **Paste into [Thisbit → Integrations → S3-compatible](https://thisbit.ai/dashboard/integrations.html#key-vault-card):**
   - **Endpoint**
   - **Bucket**
   - **Access Key ID** and **Secret Access Key**

| Provider | Endpoint | Where to create bucket + key |
| --- | --- | --- |
| **Cloudflare R2** | `https://<account_id>.r2.cloudflarestorage.com` (EU: `https://<account_id>.eu.r2.cloudflarestorage.com`) | R2 → Create bucket → Manage R2 API Tokens → *Object Read & Write* on that bucket ([Terraform bucket](cloudflare-r2/)) |
| **Hetzner Object Storage** | `https://<fsn1\|nbg1\|hel1>.your-objectstorage.com` | Cloud Console → Object Storage → Create Bucket → S3 Credentials (use a dedicated project so keys only see this bucket) |
| **Scaleway Object Storage** | `https://s3.<fr-par\|nl-ams\|pl-waw>.scw.cloud` | Object Storage → Create bucket → IAM → Applications & API keys (scoped to the bucket/project) |
| **DigitalOcean Spaces** | `https://<ams3\|fra1\|nyc3>.digitaloceanspaces.com` | Spaces Object Storage → Create Space → Manage Keys → Create Spaces Access Key (Limited Access to that Space) |
| **Backblaze B2** | `https://s3.<region>.backblazeb2.com` | Buckets → Create a Bucket (Private) → Application Keys → Add a New Application Key (restricted to that bucket) |
| **MinIO / Garage / Ceph** | `https://<your-s3-host>` | `mc mb myminio/<bucket>` and attach a policy allowing `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on `arn:aws:s3:::<bucket>/*` |
| **AWS S3** | `https://s3.<region>.amazonaws.com` | See [`aws/`](aws/) Terraform (`aws iam create-access-key` mints the key outside Terraform state) |
