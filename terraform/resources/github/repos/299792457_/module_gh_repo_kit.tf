module "repository" {
  source = "git::https://github.com/zunoser/tfmodule-gh-repo-kit.git?ref=v0.1.0"

  name        = "299792457_"
  description = ""
  visibility  = "private"

  general = {
    default_branch = "main"
  }

  default_branch_ruleset = null
}
