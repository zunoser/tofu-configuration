package main

import rego.v1

test_deny_github_issue_label_description if {
	every seed in github_issue_label_description_seeds {
		result := deny_github_issue_label_description with input as wrap_single_resource(seed.resource)
		result == seed.exp
	}
}

github_issue_label_description_seeds := [
	{
		"exp": set(),
		"resource": {
			"address": "github_issue_label.main",
			"type": "github_issue_label",
			"values": {"description": "foo"},
		},
	},
	{
		"exp": {github_issue_label_description_denial("github_issue_label.main")},
		"resource": {
			"address": "github_issue_label.main",
			"type": "github_issue_label",
			"values": {"description": ""},
		},
	},
	{
		"exp": {github_issue_label_description_denial("github_issue_label.main")},
		"resource": {
			"address": "github_issue_label.main",
			"type": "github_issue_label",
			"values": {"description": null},
		},
	},
	{
		"exp": {github_issue_label_description_denial("github_issue_label.main")},
		"resource": {
			"address": "github_issue_label.main",
			"type": "github_issue_label",
			"values": {},
		},
	},
]

github_issue_label_description_denial(address) := sprintf(
	"%s: [%s](%s)",
	[address, github_issue_label_description_message, github_issue_label_description_policy_url],
)
