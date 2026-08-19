output "bucket_name" {
  description = "R2 state bucket name."
  value       = cloudflare_r2_bucket.state.name
}

output "s3_endpoint" {
  description = "S3-compatible endpoint used by OpenTofu."
  value       = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
}
