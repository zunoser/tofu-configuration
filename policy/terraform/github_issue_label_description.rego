package main

import rego.v1

github_issue_label_description_message := "github_issue_label's description is required"

github_issue_label_description_policy_url := concat("", [
	"https://github.com/yutakobayashidev/tofu-configuration/blob/main/",
	"policy/terraform/github_issue_label_description.rego",
])

allow_github_issue_label_description(values) if {
	values.description != null
	values.description != ""
}

deny_github_issue_label_description contains message if {
	walk(input.planned_values.root_module, [_, value])
	value.type == "github_issue_label"
	not allow_github_issue_label_description(value.values)
	message := sprintf(
		"%s: [%s](%s)",
		[
			value.address,
			github_issue_label_description_message,
			github_issue_label_description_policy_url,
		],
	)
}
