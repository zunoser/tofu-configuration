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

Enable R2 for the Cloudflare account, then create a bootstrap Account API Token with these account-scoped permissions:

- `Workers R2 Storage Write`
- `Account API Tokens Write`

The first permission creates the bucket. The second creates the bucket-scoped Account API Token used by the S3 backend. Then run:

```sh
export CLOUDFLARE_API_TOKEN=...
export TF_VAR_cloudflare_account_id=...

scripts/bootstrap-r2-state create
```

The command shows the plan and asks for apply confirmation. It creates both the bucket and its state token. The bucket has `prevent_destroy`. The temporary `terraform/bootstrap/r2-state/terraform.tfstate` contains the token secret, is ignored by Git, and must never be committed.

If the temporary state is lost before migration, recreate it without touching the existing bucket:

```sh
scripts/bootstrap-r2-state import
```

## Preserve backend credentials

The bootstrap root creates an Account API Token scoped only to `zunoser-tofu-state`, with `Workers R2 Storage Bucket Item Read` and `Workers R2 Storage Bucket Item Write`. Its ID is the S3 access key ID; the SHA-256 digest of its value is the S3 secret access key.

Before migration, retrieve both outputs and store them in a password manager or the trusted CI secret store. Do not paste them into issues, pull requests, or chat:

```sh
jq -r '.outputs.r2_access_key_id.value' terraform/bootstrap/r2-state/terraform.tfstate
jq -r '.outputs.r2_secret_access_key.value' terraform/bootstrap/r2-state/terraform.tfstate
```

Migrate the bootstrap state after preserving the credentials:

```sh
scripts/bootstrap-r2-state migrate
```

The helper reads the backend credentials from the temporary local state without printing them, runs `tofu init -migrate-state`, verifies that the state can be pulled from R2, and leaves any local backup for manual recovery. Securely archive that backup, then remove the working-copy state files. Future operations on the bootstrap root use R2 like every other root and require both the preserved R2 backend credentials and a Cloudflare provider token.

If migration finished before the credentials were preserved, retrieve them once from `terraform/bootstrap/r2-state/terraform.tfstate.backup` using the same `jq` expressions above, store them securely, and then archive or remove the backup.

## Initialize new state roots

The Organization root and the original 21 repository roots were initialized and imported on 2026-08-19. New roots, including `tfmodule-gh-repo-kit`, receive their own state key when created. For a future root that has no state yet, initialize it with `-reconfigure`:

```sh
tofu -chdir=terraform/resources/github/repos/<name> init -reconfigure
```

Run `tofu plan` and review every proposed change before applying.

If a root ever has real local state, back it up and use `tofu init -migrate-state` instead. Never use `-reconfigure` to discard an existing state location.

## Recovery limitation

R2 provides strong consistency and supports the conditional writes used by `use_lockfile`, but it does not provide S3 bucket versioning. The lock prevents concurrent writers; it does not provide state history. Before enabling automatic apply, add an independent backup of state objects and test restoration, or move to a backend with native version history.
