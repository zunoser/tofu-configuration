package main

import rego.v1

hyphen_in_resource_name_message := concat(" ", [
	"リソース名にハイフン (-) が含まれています。",
	"アンダースコア (_) を使用してください。",
	"`tfmv -r '-/_'` で一括修正できます。",
	"参照:",
	"https://developer.hashicorp.com/terraform/language/style#resource-naming",
	"https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure?hl=ja",
])

hyphen_in_resource_name_policy_url := concat("", [
	"https://github.com/yutakobayashidev/tofu-configuration/blob/main/",
	"policy/terraform/hyphen_in_resource_name.rego",
])

deny_hyphen_in_resource_name contains message if {
	walk(input.planned_values.root_module, [path, value])
	is_resource_path(path)
	value.mode == "managed"
	contains(value.name, "-")
	message := sprintf(
		"%s: [%s](%s)",
		[
			value.address,
			hyphen_in_resource_name_message,
			hyphen_in_resource_name_policy_url,
		],
	)
}

is_resource_path(path) if {
	count(path) == 2
	path[0] == "resources"
}

is_resource_path(path) if {
	count(path) > 2
	count(path) % 2 == 0
	path[count(path) - 2] == "resources"
	every i in numbers.range(0, (count(path) - 4) / 2) {
		path[i * 2] == "child_modules"
	}
}
