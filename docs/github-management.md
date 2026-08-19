# GitHub management

## Design

The organization root at `terraform/resources/github/` owns members and teams. Each directory below `repos/` is a separate OpenTofu root and calls `terraform/modules/github-repository`. This keeps repository changes isolated and makes a future one-repository-per-state migration mechanical.

The shared module currently manages:

- repository settings and secure defaults;
- the default branch;
- a pull-request ruleset that blocks deletion and force pushes;
- maintain and push access for GitHub teams;
- GitHub Environments.

Routine data belongs in `terraform.tfvars` or a repository module call. Shared policy belongs in the module or `policy/terraform/`.

## Pull request workflow

CI checks formatting, Rego lint/tests, Conftest tests, and every OpenTofu root with `init -backend=false` and `validate`. It intentionally does not plan or apply: the GitHub App and remote backend have not been configured yet.

The repository generator writes a new root below `repos/` and opens a pull request. The repository itself is created only after a future apply pipeline is enabled.

## Production rollout

The following values and identities must be decided before enabling apply:

1. Configure a remote backend and add a unique state key to the organization root and every repository root.
2. Create separate GitHub Apps for pull-request plans and protected-main applies.
3. Use workload identity federation for backend access; do not store long-lived cloud credentials in GitHub Secrets.
4. Add changed-directory matrix plan/apply workflows and run Conftest against plan JSON.
5. Extract the repository name from `module_gh_repo_kit.tf` when issuing installation tokens so each job can access only its target repository.
6. Add rollback protection before apply, then protect the apply GitHub Environment with required reviewers.

These steps are intentionally not represented by skipped or placeholder jobs. They require real backend and identity choices; enabling them with dummy values would create a misleading deployment path.

## Difference from the reference design

The reference keeps its repository module in a separately versioned repository. This project starts with a local module so `init` and `validate` work without private Git credentials. Split it into a tagged module repository only when another configuration repository needs to consume it; until then, the local module has less release and dependency-management overhead.
