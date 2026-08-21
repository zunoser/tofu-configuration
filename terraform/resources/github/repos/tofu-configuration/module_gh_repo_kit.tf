module "repository" {
  source = "git::https://github.com/zunoser/tfmodule-gh-repo-kit.git?ref=v0.1.0"

  name        = "tofu-configuration"
  description = "OpenTofu configuration for homelab infrastructure"
  visibility  = "public"

  general = {
    default_branch     = "main"
    auto_init          = false
    allow_rebase_merge = false
    allow_squash_merge = true
  }

  default_branch_ruleset = {
    require_code_owner_review = false
    required_status_checks    = ["validate"]
  }
}
