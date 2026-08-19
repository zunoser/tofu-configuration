module "repository" {
  source = "../../../../modules/github-repository"

  name        = "kasumilog"
  description = "An account catalog and reproducible raw archive for Japanese central-government posts on X/Twitter"
  visibility  = "public"

  general = {
    auto_init              = false
    default_branch         = "main"
    allow_merge_commit     = true
    allow_rebase_merge     = true
    allow_squash_merge     = true
    delete_branch_on_merge = false
  }

  # Preserve the current unprotected state during import. Enable this per
  # repository after its owners confirm the standard policy.
  default_branch_ruleset = null
}
