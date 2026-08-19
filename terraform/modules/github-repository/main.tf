resource "github_repository" "this" {
  name        = var.name
  description = var.description
  visibility  = var.visibility

  has_issues      = var.general.has_issues
  has_discussions = var.general.has_discussions

  allow_merge_commit = var.general.allow_merge_commit
  allow_rebase_merge = var.general.allow_rebase_merge
  allow_squash_merge = var.general.allow_squash_merge

  archive_on_destroy     = true
  auto_init              = true
  delete_branch_on_merge = true
}

resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
  enabled    = true
}

resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = var.general.default_branch
}

data "github_team" "maintainers" {
  for_each = var.maintainers
  slug     = each.value
}

resource "github_team_repository" "maintainers" {
  for_each   = data.github_team.maintainers
  team_id    = each.value.id
  repository = github_repository.this.name
  permission = "maintain"
}

data "github_team" "writers" {
  for_each = var.writers
  slug     = each.value
}

resource "github_team_repository" "writers" {
  for_each   = data.github_team.writers
  team_id    = each.value.id
  repository = github_repository.this.name
  permission = "push"
}

resource "github_repository_environment" "this" {
  for_each    = var.environments
  repository  = github_repository.this.name
  environment = each.value
}

resource "github_repository_ruleset" "default_branch" {
  count = var.default_branch_ruleset == null ? 0 : 1

  name        = "default branch"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count = var.default_branch_ruleset.required_approvals
      require_code_owner_review       = var.default_branch_ruleset.require_code_owner_review
    }
  }
}
