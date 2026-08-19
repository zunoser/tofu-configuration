package main

import rego.v1

github_branch_protection_message := "github_branch_protection is forbidden; use github_repository_ruleset"

github_branch_protection_policy_url := concat("", [
	"https://github.com/zunoser/tofu-configuration/blob/main/",
	"policy/terraform/github_branch_protection.rego",
])

deny_github_branch_protection contains message if {
	resources := object.get(input, "resource", {})
	branch_protections := object.get(resources, "github_branch_protection", {})
	some name, configurations in branch_protections
	count(configurations) > 0
	message := sprintf(
		"github_branch_protection.%s: [%s](%s)",
		[name, github_branch_protection_message, github_branch_protection_policy_url],
	)
}
