module "repository" {
  source = "../../../../modules/github-repository"

  name        = "tfmodule-gh-repo-kit"
  description = "Reusable OpenTofu module for standardized GitHub repository management"
  visibility  = "public"

  general = {
    default_branch = "main"
  }
}
