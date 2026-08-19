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

CI intentionally does not plan or apply: the R2 backend has not been bootstrapped and the GitHub App identities have not been configured yet.

The repository generator writes a new root below `repos/` and opens a pull request. The repository itself is created only after a future apply pipeline is enabled.

## Existing-resource migration

Existing memberships and repositories use declarative `import` blocks. Do not run the imports against disposable local state. Bootstrap and initialize the [R2 backend](r2-backend.md) first, then plan one root at a time.

The initial repository inventory preserves the currently enabled merge methods and disables the standard ruleset with `default_branch_ruleset = null`. This prevents onboarding from unexpectedly changing merge policy. Vulnerability alerts are the only security default intentionally enabled by the shared module.

Roll out in this order:

1. Import and apply the Organization membership root using an Organization-owner identity or a GitHub App with Members write access.
2. Import `tofu-configuration`, review its standard ruleset plan, and apply it as the canary.
3. Import the remaining repositories individually and require a zero-surprise plan before apply.
4. For each public repository, enable the standard ruleset after its owners confirm the policy.
5. Keep `default_branch_ruleset = null` for private repositories while the Organization remains on GitHub Free, where repository rulesets are unavailable for private repositories.
6. Define teams only after ownership and membership are agreed; the current Organization has no teams, so none are invented by this configuration.

Two repositories require special attention during import: `bird` uses `backup/original-before-codex-20260624` as its default branch, and `simple-mcsrvstat-discord` is a fork whose default branch is `add-blue-map`.

## Production rollout

The following work remains before enabling apply:

1. Create the declared R2 bucket, issue bucket-scoped Object Read & Write credentials, and initialize the state roots.
2. Back up R2 state objects independently because R2 does not provide bucket versioning.
3. Create separate GitHub Apps for pull-request plans and protected-main applies.
4. Add changed-directory matrix plan/apply workflows and run Conftest against plan JSON.
5. Extract the repository name from `module_gh_repo_kit.tf` when issuing installation tokens so each job can access only its target repository.
6. Add rollback protection before apply, then protect the apply GitHub Environment with required reviewers.

R2 does not provide a direct GitHub OIDC credential exchange. Initial CI state access therefore requires the bucket-scoped R2 access key and secret; keep them separate from GitHub provider credentials and expose them only to trusted plan/apply jobs.

These steps are intentionally not represented by skipped or placeholder jobs. They require real backend and identity choices; enabling them with dummy values would create a misleading deployment path.

## Difference from the reference design

The reference keeps its repository module in a separately versioned repository. This project starts with a local module so `init` and `validate` work without private Git credentials. Split it into a tagged module repository only when another configuration repository needs to consume it; until then, the local module has less release and dependency-management overhead.
