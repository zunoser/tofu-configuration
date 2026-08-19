# R2 backend bootstrap

The GitHub Organization root and every repository root store state in the shared `zunoser-tofu-state` Cloudflare R2 bucket. Each root has an independent object key and uses OpenTofu's S3 lockfile support.

## State layout

| Root | State key |
| --- | --- |
| R2 bootstrap | `bootstrap/r2-state/terraform.tfstate` |
| GitHub Organization | `github/organization/terraform.tfstate` |
| GitHub repository | `github/repositories/<name>/terraform.tfstate` |

The S3 endpoint is supplied through `AWS_ENDPOINT_URL_S3`; it is not repeated in every `backend.tf`. R2 credentials are supplied through `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` and must never be committed or passed through `-backend-config`.

## Create the bucket with temporary local state

The bucket cannot hold its own state before it exists. The bootstrap helper therefore copies the configuration without `backend.tf` to a temporary directory and creates the bucket with a temporary local state file.

Create a Cloudflare API token with only `Workers R2 Storage Write`, then run:

```sh
export CLOUDFLARE_API_TOKEN=...
export TF_VAR_cloudflare_account_id=...

scripts/bootstrap-r2-state create
```

The command shows the plan and asks for apply confirmation. The bucket has `prevent_destroy`. The temporary `terraform/bootstrap/r2-state/terraform.tfstate` is ignored by Git and must never be committed.

If the temporary state is lost before migration, recreate it without touching the existing bucket:

```sh
scripts/bootstrap-r2-state import
```

## Create backend credentials

In Cloudflare, create an R2 API token scoped only to the `zunoser-tofu-state` bucket with Object Read & Write access. The R2 access key and secret are intentionally not created by the bootstrap root: storing their secret in local bootstrap state would make that state a credential vault.

Export the resulting credentials and endpoint:

```sh
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_ENDPOINT_URL_S3="https://${TF_VAR_cloudflare_account_id}.r2.cloudflarestorage.com"
export AWS_EC2_METADATA_DISABLED=true
```

Migrate the bootstrap state immediately after setting these variables:

```sh
scripts/bootstrap-r2-state migrate
```

The helper runs `tofu init -migrate-state`, verifies that the state can be pulled from R2, and leaves any local backup for manual recovery. Securely archive that backup, then remove the working-copy state files. Future operations on the bootstrap root use R2 like every other root and require both the R2 backend credentials and `CLOUDFLARE_API_TOKEN`.

## Initialize state roots

These roots do not currently have local state, so initialize them with `-reconfigure`:

```sh
tofu -chdir=terraform/resources/github init -reconfigure
tofu -chdir=terraform/resources/github/repos/tofu-configuration init -reconfigure
```

Use the Organization root first, then `tofu-configuration` as the repository canary. Run `tofu plan` and review every import and proposed change before applying. Initialize the remaining repository roots only after the canary is clean.

If a root ever has real local state, back it up and use `tofu init -migrate-state` instead. Never use `-reconfigure` to discard an existing state location.

## Recovery limitation

R2 provides strong consistency and supports the conditional writes used by `use_lockfile`, but it does not provide S3 bucket versioning. The lock prevents concurrent writers; it does not provide state history. Before enabling automatic apply, add an independent backup of state objects and test restoration, or move to a backend with native version history.
