package main

import rego.v1

wrap_single_resource(resource) := {"planned_values": {"root_module": {"resources": [resource]}}}
