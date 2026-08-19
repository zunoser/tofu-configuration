module "repository" {
  source = "../../../../modules/github-repository"

  name        = "bird"
  description = ""
  visibility  = "private"

  general = {
    auto_init              = false
    default_branch         = "backup/original-before-codex-20260624"
    allow_merge_commit     = true
    allow_rebase_merge     = true
    allow_squash_merge     = true
    delete_branch_on_merge = false
  }

  # Preserve the current unprotected state during import. Enable this per
  # repository after its owners confirm the standard policy.
  default_branch_ruleset = null
}
