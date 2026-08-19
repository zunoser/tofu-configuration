package main

import rego.v1

test_warn_invalid_tfvars_user if {
	result := warn_invalid_tfvars_user with input as {"users": [
		{"username": "valid-user"},
		{"username": "invalid-user"},
	]}
		with data.github_members as ["valid-user"]

	count(result) == 1
	some warning in result
	contains(warning.msg, "@invalid-user")
}

test_github_member_comparison_is_case_insensitive if {
	result := warn_invalid_tfvars_user with input as {"users": [{"username": "Mixed-Case"}]}
		with data.github_members as ["mixed-case"]

	count(result) == 0
}

test_warn_invalid_tfvars_team_member if {
	input_data := {"teams": {"developers": {"members": ["valid-user", "invalid-user"]}}}
	result := warn_invalid_tfvars_team_member with input as input_data
		with data.github_members as ["valid-user"]

	count(result) == 1
	some warning in result
	contains(warning.msg, "teams.developers.members[]")
	contains(warning.msg, "@invalid-user")
}

test_deny_undeclared_tfvars_team_member if {
	input_data := {
		"users": [{"username": "valid-user"}],
		"teams": {"developers": {"members": ["valid-user", "undeclared-user"]}},
	}
	result := deny_undeclared_tfvars_team_member with input as input_data

	count(result) == 1
	some violation in result
	contains(violation.msg, "@undeclared-user")
}

test_declared_tfvars_team_member_comparison_is_case_insensitive if {
	input_data := {
		"users": [{"username": "Mixed-Case"}],
		"teams": {"developers": {"members": ["mixed-case"]}},
	}
	result := deny_undeclared_tfvars_team_member with input as input_data

	count(result) == 0
}
