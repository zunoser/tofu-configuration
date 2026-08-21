# tofu-configuration

OpenTofu configuration for the `zunoser` GitHub organization and homelab infrastructure.

The GitHub layout follows the operating model described in [10X's GitHub management article](https://product.10x.co.jp/entry/2026/07/06/101918): organization membership is centralized, repository settings use a shared module, and every repository has an independent OpenTofu root directory.

## GitHub layout

```text
terraform/
├── bootstrap/r2-state/                       # Creates the shared R2 bucket and state token
├── modules/github-repository/               # Shared repository defaults
└── resources/github/
    ├── backend.tf                            # Organization state
    ├── terraform.tfvars                      # Members and teams
    └── repos/
        ├── tofu-configuration/backend.tf     # One state per repository
        └── ...                               # All 22 managed repositories
```

The shared module enables vulnerability alerts and branch cleanup, disables merge commits and rebase merges by default, and protects the default branch with a pull-request ruleset. Rulesets can require named GitHub Actions checks; `tofu-configuration` requires `validate`. Repository roots can additionally grant team access and create GitHub Environments.

The existing Organization inventory is stored in R2-backed state: all 19 memberships and the repository, default-branch, and vulnerability-alert resources for the original 21 repositories have been imported. The completed migration blocks were removed. `tfmodule-gh-repo-kit` was then created as the 22nd managed repository with the standard ruleset enabled from the start. The other 20 imported repositories preserve their current merge methods and start without a new ruleset. `tofu-configuration` has been reconciled as the first imported repository using the standard policy.

## Local checks

Enter the reproducible Nix development shell, then run the same checks as CI:

```sh
nix develop
scripts/check
```

No GitHub credentials or remote state are needed for these static checks. To inspect a real plan, export `GITHUB_TOKEN` and run `tofu plan` from the relevant root directory.

The same command validates `renovate.json` in strict mode and runs Conftest against every Terraform file. The static policies require `integrations/github` as the GitHub provider and prohibit legacy `github_branch_protection` resources in favor of Repository Rulesets. `nix fmt` runs the Renovate validator through treefmt. Renovate manages the flake inputs through its opt-in Nix manager and labels dependency pull requests with `deps`.

The GitHub roots use the shared `zunoser-tofu-state` R2 bucket with independent state keys and native S3 lockfiles. The bucket and its bucket-scoped state token are declared in `terraform/bootstrap/r2-state`; their state was created locally once, then migrated into the same R2 bucket. See [R2 backend bootstrap](docs/r2-backend.md) for credentials and recovery.

To compare the declared users and team members with the live GitHub Organization:

```sh
scripts/check-github-members
```

This command uses the authenticated `gh` CLI and requires Organization `Members: read` access. CI runs it on trusted `main` pushes and manual runs when the `GH_ORG_MEMBERS_TOKEN` secret is configured. It is not given to pull-request code. The built-in `GITHUB_TOKEN` is not used because it cannot reliably list every Organization member.

## Common changes

Edit `terraform/resources/github/terraform.tfvars` to add or move an organization member. Resource logic should not be changed for routine membership updates.

Create a repository configuration locally with:

```sh
scripts/new-github-repository example-repo "Example repository" private main
```

The same generator is available from the **Create repository configuration** GitHub Actions workflow and opens a pull request automatically.

See [GitHub management](docs/github-management.md) for the design and operating model, and [R2 backend bootstrap](docs/r2-backend.md) for state initialization and recovery constraints.
