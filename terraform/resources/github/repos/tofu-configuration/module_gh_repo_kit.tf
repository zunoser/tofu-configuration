module "repository" {
  source = "../../../../modules/github-repository"

  name        = "tofu-configuration"
  description = "OpenTofu configuration for homelab infrastructure"
  visibility  = "public"

  general = {
    default_branch     = "main"
    allow_rebase_merge = false
    allow_squash_merge = true
  }
}
