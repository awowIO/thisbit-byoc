terraform {
  required_providers {
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 5.0" }
  }
}
variable "cloudflare_account_id" { type = string }
variable "bucket_name" { type = string }

resource "cloudflare_r2_bucket" "thisbit" {
  account_id = var.cloudflare_account_id
  name       = var.bucket_name
  lifecycle { prevent_destroy = true }
}

output "endpoint" { value = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com" }
output "bucket" { value = cloudflare_r2_bucket.thisbit.name }
