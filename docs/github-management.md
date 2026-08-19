# GitHub management

## Design

The organization root at `terraform/resources/github/` owns members and teams. Each directory below `repos/` is a separate OpenTofu root and calls `terraform/modules/github-repository`. Every root has an independent state key in the shared R2 bucket, keeping repository changes isolated.

The checked-in inventory mirrors the Organization as observed on 2026-08-19: 19 active members, no teams, and 21 repositories. Organization owners are represented with `role = "admin"`. Email addresses are not part of the input because GitHub does not expose a reliable address for every member and the provider resources do not use it.

The shared module currently manages:

- repository settings and secure defaults;
- the default branch;
- a pull-request ruleset that blocks deletion and force pushes;
- maintain and push access for GitHub teams;
- GitHub Environments.

Routine data belongs in `terraform.tfvars` or a repository module call. Shared policy belongs in the module or `policy/terraform/`.

## Pull request workflow

CI checks formatting, Rego lint/tests, Conftest tests, the R2 bootstrap root, and every OpenTofu root with `init -backend=false` and `validate`. Static CI never accesses remote state. On trusted `main` pushes and manual runs, it also fetches the live Organization membership and checks `terraform.tfvars` against GitHub as the source of truth when `GH_ORG_MEMBERS_TOKEN` is configured. The token needs only Organization `Members: read`; CI reports an explicit notice and skips this external check until the secret is configured. The external check does not run on pull requests, so untrusted pull-request code never receives the secret. The built-in `GITHUB_TOKEN` is not a fallback because it cannot reliably list private Organization memberships.

The member policy follows the approach in [10X's dynamic Conftest article](https://product.10x.co.jp/entry/2026/04/07/170704). A configured user or team member missing from the live Organization produces a warning so a pull request that introduces a pending invitation is not blocked. A team member missing from the local `users` declaration is denied because the OpenTofu configuration cannot resolve that membership. GitHub usernames are compared case-insensitively. Run the same live check locally with an authenticated Nix-shell `gh`:

```sh
scripts/check-github-members
```

The command fails instead of evaluating against an empty member list when the API call returns no members.

The Terraform workflows follow the changed-directory matrix design from [10X's GitHub management article](https://product.10x.co.jp/entry/2026/07/06/101918). `scripts/changed-stacks` maps a pull request or main push to independent Organization or repository roots. A shared `terraform/modules/github-repository` change fans out to every repository root because this project keeps the module locally. `scripts/target-repository` parses `module_gh_repo_kit.tf` with `hcl2json` and rejects a directory whose declared repository name does not match its path. Removed or renamed roots fail and require an explicit state migration.

`terraform-plan.yml` runs only for same-repository pull requests, uses a read-only R2 token with locking disabled, obtains a short-lived plan App token, checks plan JSON with Conftest, and comments the redacted human-readable plan. Fork pull requests receive only static CI. `terraform-apply.yml` replans on protected `main`, rejects a stale workflow when a newer commit touched the same root or shared module, applies the saved plan with a read/write R2 token, and serializes each state with a per-root concurrency group. The R2 bootstrap root is intentionally excluded from automatic routing.

Remote jobs are disabled until the required identities and recovery controls exist. Configure these repository variables and Environment values before enabling them:

| Location | Name | Purpose |
| --- | --- | --- |
| Repository variable | `TF_PLAN_ENABLED` | Set to `true` after plan prerequisites are ready |
| Repository variable | `TF_APPLY_ENABLED` | Set to `true` after apply prerequisites are ready |
| `terraform-plan` variable | `GH_APP_TF_PLAN_CLIENT_ID` | Read-only GitHub App client ID |
| `terraform-plan` variable | `R2_ENDPOINT` | R2 S3 endpoint |
| `terraform-plan` secret | `GH_APP_TF_PLAN_PRIVATE_KEY` | Plan App private key |
| `terraform-plan` secrets | `R2_PLAN_ACCESS_KEY_ID`, `R2_PLAN_SECRET_ACCESS_KEY` | Read-only state credentials, provisioned only after bootstrap state isolation |
| `terraform-apply` variable | `GH_APP_TF_APPLY_CLIENT_ID` | Write GitHub App client ID |
| `terraform-apply` variable | `R2_ENDPOINT` | R2 S3 endpoint |
| `terraform-apply` secret | `GH_APP_TF_APPLY_PRIVATE_KEY` | Apply App private key |
| `terraform-apply` secrets | `R2_APPLY_ACCESS_KEY_ID`, `R2_APPLY_SECRET_ACCESS_KEY` | Read/write state credentials |

The plan App needs Organization Members read and repository Administration, Environments, and Vulnerability alerts read. The apply App needs Members write for the Organization root and the corresponding repository permissions at write level. Installation tokens are down-scoped again per matrix job. Both Environments need required reviewers because OpenTofu evaluates pull-request configuration while credentials are present. Do not enable either gate while every Organization member has repository admin access, and do not enable apply until state recovery has been tested.

The current bootstrap state shares `zunoser-tofu-state` with the GitHub roots and contains the read/write state credential. A bucket-scoped read-only token could therefore read the bootstrap state and recover write access. Before provisioning `R2_PLAN_*`, move the bootstrap root to a separate R2 backend bucket (it remains R2-managed), then create a read-only token scoped to the GitHub state bucket. R2 does not support object-prefix token scopes, so Environment approval remains part of the plan trust boundary.

The repository generator writes a new root below `repos/` and opens a pull request. The repository itself is created only after a future apply pipeline is enabled.

## Existing-resource migration

The existing-resource migration is complete. The R2-backed state contains all 19 active Organization memberships and three resources for each of the 21 repositories: the repository, its default branch, and its vulnerability-alert setting. The completed declarative `import` blocks were removed on 2026-08-19.

The Organization post-import plan had no changes. Repository settings were not applied during import; CLI import recorded the existing objects without changing GitHub.

The other 20 repository definitions preserve their currently enabled merge methods and disable the standard ruleset with `default_branch_ruleset = null`. This prevents reconciliation from unexpectedly changing merge policy. Vulnerability alerts are the only security default intentionally enabled by the shared module.

Reconcile the imported configuration in this order:

1. Review the `tofu-configuration` repository-setting changes and standard ruleset plan, then apply it as the canary.
2. Review the remaining repositories individually and require a zero-surprise plan before apply.
3. For each public repository, enable the standard ruleset after its owners confirm the policy.
4. Keep `default_branch_ruleset = null` for private repositories while the Organization remains on GitHub Free, where repository rulesets are unavailable for private repositories.
5. Define teams only after ownership and membership are agreed; the current Organization has no teams, so none are invented by this configuration.

Two repositories require special attention during reconciliation: `bird` uses `backup/original-before-codex-20260624` as its default branch, and `simple-mcsrvstat-discord` is a fork whose default branch is `add-blue-map`.

## Production rollout

The following external setup remains before enabling remote jobs:

1. Preserve the generated R2 credentials outside the bootstrap state and back up R2 state objects independently because R2 does not provide bucket versioning.
2. Move bootstrap state to a separate R2 backend bucket, then provision a read-only token scoped to the GitHub state bucket.
3. Create and install separate GitHub Apps for pull-request plans and protected-main applies.
4. Create the two GitHub Environments, configure their variables and secrets, and require reviewers for apply.
5. Enable and test plan on one existing repository, then enable apply after its plan is reviewed.
6. Design a separate approved path for creating a repository; a token cannot be scoped to a repository that does not exist, and the normal workflow deliberately has no Organization-wide fallback.

R2 does not provide a direct GitHub OIDC credential exchange. Initial CI state access therefore requires the bucket-scoped R2 access key and secret; keep them separate from GitHub provider credentials and expose them only to trusted plan/apply jobs.

The workflows expose explicit feature gates rather than dummy credentials or an Organization-wide token fallback. Detection and static validation always run; remote jobs remain skipped until the gates are deliberately enabled.

## Difference from the reference design

The reference keeps its repository module in a separately versioned repository. This project starts with a local module so `init` and `validate` work without private Git credentials. Split it into a tagged module repository only when another configuration repository needs to consume it; until then, the local module has less release and dependency-management overhead.
