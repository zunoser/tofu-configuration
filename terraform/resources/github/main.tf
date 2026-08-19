locals {
  users_by_name = { for user in var.users : user.username => user }

  team_memberships = merge([
    for team_name, team in var.teams : {
      for username in team.members : "${team_name}:${username}" => {
        team_name = team_name
        username  = username
        role      = try(local.users_by_name[username].role, "member") == "admin" ? "maintainer" : "member"
      }
    }
  ]...)
}

resource "github_membership" "members" {
  for_each = local.users_by_name

  username = each.value.username
  role     = each.value.role
}

resource "github_team" "teams" {
  for_each = var.teams

  name        = each.key
  description = each.value.description
  privacy     = each.value.privacy
}

resource "github_team_membership" "members" {
  for_each = local.team_memberships

  team_id  = github_team.teams[each.value.team_name].id
  username = github_membership.members[each.value.username].username
  role     = each.value.role
}
