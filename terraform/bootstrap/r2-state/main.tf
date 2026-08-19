resource "cloudflare_r2_bucket" "state" {
  account_id = var.cloudflare_account_id
  name       = "zunoser-tofu-state"
  location   = "apac"

  lifecycle {
    prevent_destroy = true
  }
}

data "cloudflare_account_api_token_permission_groups_list" "state" {
  account_id = var.cloudflare_account_id
  max_items  = 1000
}

locals {
  r2_permission_groups = {
    for permission in data.cloudflare_account_api_token_permission_groups_list.state.result :
    permission.name => permission.id
    if contains([
      "Workers R2 Storage Bucket Item Read",
      "Workers R2 Storage Bucket Item Write",
    ], permission.name)
  }
}

resource "cloudflare_account_token" "state" {
  account_id = var.cloudflare_account_id
  name       = "zunoser-tofu-state"

  policies = [{
    effect = "allow"
    resources = jsonencode({
      "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${cloudflare_r2_bucket.state.name}" = "*"
    })
    permission_groups = [
      for name in [
        "Workers R2 Storage Bucket Item Read",
        "Workers R2 Storage Bucket Item Write",
      ] : { id = local.r2_permission_groups[name] }
    ]
  }]
}
