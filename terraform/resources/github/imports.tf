# Import existing memberships before OpenTofu starts managing them. The block is
# data-driven so new members only need an entry in terraform.tfvars.
import {
  for_each = local.users_by_name

  to = github_membership.members[each.key]
  id = "${var.organization}:${each.key}"
}
