resource "cloudflare_r2_bucket" "state" {
  account_id = var.cloudflare_account_id
  name       = "zunoser-tofu-state"
  location   = "apac"

  lifecycle {
    prevent_destroy = true
  }
}
