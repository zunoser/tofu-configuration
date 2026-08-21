# GitHub management

## Design

The organization root at `terraform/resources/github/` owns members and teams. Each directory below `repos/` is a separate OpenTofu root and calls `terraform/modules/github-repository`. Every root has an independent state key in the shared R2 bucket, keeping repository changes isolated.

The checked-in inventory contains 19 active members, no teams, and 22 repositories. The original 21 repositories mirror the Organization inventory observed on 2026-08-19; `tfmodule-gh-repo-kit` was added afterward. Organization owners are represented with `role = "admin"`. Email addresses are not part of the input because GitHub does not expose a reliable address for every member and the provider resources do not use it.

The shared module currently manages:

- repository settings and secure defaults;
- the default branch;
- a pull-request ruleset that blocks deletion and force pushes and can require named GitHub Actions checks;
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

Static Conftest checks run against every `.tf` file. They require the maintained `integrations/github` provider source and reject legacy `github_branch_protection` resources so branch governance stays on Repository Rulesets. Policies for direct collaborators and redundant team grants will be added only when those concepts exist in the configuration schema.

CI intentionally does not plan or apply: the R2 backend is bootstrapped, but CI state credentials and the GitHub App identities have not been configured yet.

The repository generator writes a new root below `repos/` and opens a pull request. The repository itself is created only after a future apply pipeline is enabled.

## Existing-resource migration

The existing-resource migration is complete. The R2-backed state contains all 19 active Organization memberships and three resources for each of the original 21 repositories: the repository, its default branch, and its vulnerability-alert setting. The completed declarative `import` blocks were removed on 2026-08-19. The `tfmodule-gh-repo-kit` root was created directly by OpenTofu and therefore required no import.

The Organization post-import plan had no changes. Repository settings were not applied during import; CLI import recorded the existing objects without changing GitHub. The `tofu-configuration` canary was applied on 2026-08-19 and its post-apply plan had no changes.

The other 20 repository definitions preserve their currently enabled merge methods and disable the standard ruleset with `default_branch_ruleset = null`. This prevents reconciliation from unexpectedly changing merge policy. Vulnerability alerts are the only security default intentionally enabled by the shared module. The `tofu-configuration` canary requires one approval but temporarily disables CODEOWNER review because its sole CODEOWNER cannot approve their own pull requests; enable it after adding another responsible reviewer.

Continue reconciling the imported configuration in this order:

1. Review the remaining repositories individually and require a zero-surprise plan before apply.
2. For each public repository, enable the standard ruleset after its owners confirm the policy.
3. Keep `default_branch_ruleset = null` for private repositories while the Organization remains on GitHub Free, where repository rulesets are unavailable for private repositories.
4. Define teams only after ownership and membership are agreed; the current Organization has no teams, so none are invented by this configuration.

Two repositories require special attention during reconciliation: `bird` uses `backup/original-before-codex-20260624` as its default branch, and `simple-mcsrvstat-discord` is a fork whose default branch is `add-blue-map`.

## Production rollout

The following work remains before enabling apply:

1. Preserve the generated R2 credentials outside the bootstrap state, then review and apply the remaining imported repository configuration.
2. Back up R2 state objects independently because R2 does not provide bucket versioning.
3. Create separate GitHub Apps for pull-request plans and protected-main applies.
4. Add changed-directory matrix plan/apply workflows and run Conftest against plan JSON.
5. Extract the repository name from `module_gh_repo_kit.tf` when issuing installation tokens so each job can access only its target repository.
6. Add rollback protection before apply, then protect the apply GitHub Environment with required reviewers.

R2 does not provide a direct GitHub OIDC credential exchange. Initial CI state access therefore requires the bucket-scoped R2 access key and secret; keep them separate from GitHub provider credentials and expose them only to trusted plan/apply jobs.

These steps are intentionally not represented by skipped or placeholder jobs. They require real backend and identity choices; enabling them with dummy values would create a misleading deployment path.

## Module repository rollout

The shared module is being moved to the public `zunoser/tfmodule-gh-repo-kit` repository to match the reference design. Its repository definition remains in this configuration. The initial module code is reviewed under the standard ruleset, then tagpr publishes `v0.1.0`; only after that tag exists will consumers replace the local source with a pinned Git source and the local module be removed. This order avoids a bootstrap dependency on an unpublished module.
