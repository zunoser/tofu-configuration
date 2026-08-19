package main

import rego.v1

github_provider_source_message := "GitHub provider source must be integrations/github"

github_provider_source_policy_url := concat("", [
	"https://github.com/zunoser/tofu-configuration/blob/main/",
	"policy/terraform/github_provider_source.rego",
])

github_provider_source_denial := sprintf(
	"github: [%s](%s)",
	[github_provider_source_message, github_provider_source_policy_url],
)

deny_github_provider_source contains github_provider_source_denial if {
	some terraform_block in object.get(input, "terraform", [])
	some required_providers in object.get(terraform_block, "required_providers", [])
	github := object.get(required_providers, "github", null)
	github != null
	object.get(github, "source", "") != "integrations/github"
}
