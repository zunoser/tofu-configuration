output "bucket_name" {
  description = "R2 state bucket name."
  value       = cloudflare_r2_bucket.state.name
}

output "s3_endpoint" {
  description = "S3-compatible endpoint used by OpenTofu."
  value       = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
}

output "r2_access_key_id" {
  description = "Access key ID for the bucket-scoped R2 state token."
  value       = cloudflare_account_token.state.id
}

output "r2_secret_access_key" {
  description = "Secret access key for the bucket-scoped R2 state token."
  value       = sha256(cloudflare_account_token.state.value)
  sensitive   = true
}
