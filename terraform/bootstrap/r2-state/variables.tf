variable "cloudflare_account_id" {
  description = "Cloudflare account ID that owns the state bucket."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.cloudflare_account_id))
    error_message = "cloudflare_account_id must be a 32-character lowercase hexadecimal string."
  }
}
