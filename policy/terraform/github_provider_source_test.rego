package main

import rego.v1

test_allow_integrations_github_provider if {
	result := deny_github_provider_source with input as github_provider_configuration("integrations/github")
	result == set()
}

test_deny_hashicorp_github_provider if {
	result := deny_github_provider_source with input as github_provider_configuration("hashicorp/github")
	result == {github_provider_source_denial}
}

test_deny_github_provider_without_source if {
	result := deny_github_provider_source with input as {
		"terraform": [{"required_providers": [{"github": {"version": "~> 6.0"}}]}],
	}
	result == {github_provider_source_denial}
}

test_ignore_unrelated_provider if {
	result := deny_github_provider_source with input as {
		"terraform": [{"required_providers": [{"cloudflare": {"source": "cloudflare/cloudflare"}}]}],
	}
	result == set()
}

github_provider_configuration(source) := {
	"terraform": [{"required_providers": [{"github": {"source": source}}]}],
}
