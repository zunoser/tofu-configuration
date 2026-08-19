# tofu-configuration

OpenTofu configuration for the `zunoser` GitHub organization and homelab infrastructure.

The GitHub layout follows the operating model described in [10X's GitHub management article](https://product.10x.co.jp/entry/2026/07/06/101918): organization membership is centralized, repository settings use a shared module, and every repository has an independent OpenTofu root directory.

## GitHub layout

```text
terraform/
├── modules/github-repository/               # Shared repository defaults
└── resources/github/
    ├── terraform.tfvars                      # Members and teams
    └── repos/
        ├── tofu-configuration/               # One repository root directory
        └── ...                               # All 21 existing repositories
```

The shared module enables vulnerability alerts and branch cleanup, disables merge commits and rebase merges by default, and protects the default branch with a pull-request ruleset. Repository roots can additionally grant team access and create GitHub Environments.

The existing Organization inventory is intentionally migration-safe: all 19 members and 21 repositories have declarative import blocks. The other 20 repositories preserve their current merge methods and start without a new ruleset. `tofu-configuration` remains the first repository opted into the standard policy.

## Local checks

Enter the reproducible Nix development shell, then run the same checks as CI:

```sh
nix develop
scripts/check
```

No GitHub credentials or remote state are needed for these static checks. To inspect a real plan, export `GITHUB_TOKEN` and run `tofu plan` from the relevant root directory.

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

See [GitHub management](docs/github-management.md) for the design, operating model, and the remaining production rollout steps.
