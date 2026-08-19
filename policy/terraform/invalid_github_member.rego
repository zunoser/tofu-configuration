package main

import rego.v1

valid_github_members contains lower(member) if {
	some member in data.github_members
}

configured_users contains lower(user.username) if {
	some user in input.users
}

is_valid_github_member(username) if {
	lower(username) in valid_github_members
}

warn_invalid_tfvars_user contains {"msg": message} if {
	some user in input.users
	username := user.username
	not is_valid_github_member(username)
	message := sprintf(
		"users[].username - @%s is not currently a member of the GitHub organization",
		[username],
	)
}

warn_invalid_tfvars_team_member contains {"msg": message} if {
	some team_name, team in input.teams
	some username in team.members
	not is_valid_github_member(username)
	message := sprintf(
		"teams.%s.members[] - @%s is not currently a member of the GitHub organization",
		[team_name, username],
	)
}

deny_undeclared_tfvars_team_member contains {"msg": message} if {
	some team_name, team in input.teams
	some username in team.members
	not lower(username) in configured_users
	message := sprintf(
		"teams.%s.members[] - @%s must also be declared in users[]",
		[team_name, username],
	)
}
