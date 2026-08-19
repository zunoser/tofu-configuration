package main

import rego.v1

test_deny_github_branch_protection if {
	result := deny_github_branch_protection with input as {
		"resource": {"github_branch_protection": {"main": [{"pattern": "main"}]}},
	}
	result == {github_branch_protection_denial("main")}
}

test_allow_github_repository_ruleset if {
	result := deny_github_branch_protection with input as {
		"resource": {"github_repository_ruleset": {"main": [{"target": "branch"}]}},
	}
	result == set()
}

test_ignore_empty_github_branch_protection if {
	result := deny_github_branch_protection with input as {
		"resource": {"github_branch_protection": {}},
	}
	result == set()
}

github_branch_protection_denial(name) := sprintf(
	"github_branch_protection.%s: [%s](%s)",
	[name, github_branch_protection_message, github_branch_protection_policy_url],
)
