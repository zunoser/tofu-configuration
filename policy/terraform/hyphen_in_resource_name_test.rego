package main

import rego.v1

test_deny_hyphen_in_resource_name if {
	every seed in hyphen_in_resource_name_seeds {
		result := deny_hyphen_in_resource_name with input as seed.input
		result == seed.exp
	}
}

hyphen_in_resource_name_seeds := [
	{
		"exp": set(),
		"input": wrap_single_resource({
			"address": "google_project_iam_member.test",
			"mode": "managed",
			"name": "test",
		}),
	},
	{
		"exp": {hyphen_in_resource_name_denial("google_project_iam_member.test-1")},
		"input": wrap_single_resource({
			"address": "google_project_iam_member.test-1",
			"mode": "managed",
			"name": "test-1",
		}),
	},
	{
		"exp": set(),
		"input": wrap_single_resource({
			"address": "data.google_project.test-1",
			"mode": "data",
			"name": "test-1",
		}),
	},
	{
		"exp": set(),
		"input": wrap_single_resource({
			"address": "example_resource.test",
			"mode": "managed",
			"name": "test",
			"values": {"nested": {
				"address": "not_a_resource.test-1",
				"mode": "managed",
				"name": "test-1",
			}},
		}),
	},
	{
		"exp": {hyphen_in_resource_name_denial("module.example.google_project_iam_member.test-1")},
		"input": {"planned_values": {"root_module": {"child_modules": [child_module_with_hyphen_resource]}}},
	},
]

child_module_with_hyphen_resource := {
	"address": "module.example",
	"resources": [{
		"address": "module.example.google_project_iam_member.test-1",
		"mode": "managed",
		"name": "test-1",
	}],
}

hyphen_in_resource_name_denial(address) := sprintf(
	"%s: [%s](%s)",
	[address, hyphen_in_resource_name_message, hyphen_in_resource_name_policy_url],
)
