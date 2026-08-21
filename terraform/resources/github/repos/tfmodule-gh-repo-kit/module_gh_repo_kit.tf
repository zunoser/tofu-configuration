module "repository" {
  source = "git::https://github.com/zunoser/tfmodule-gh-repo-kit.git?ref=v0.1.0"

  name        = "tfmodule-gh-repo-kit"
  description = "Reusable OpenTofu module for standardized GitHub repository management"
  visibility  = "public"

  general = {
    default_branch = "main"
  }
}
