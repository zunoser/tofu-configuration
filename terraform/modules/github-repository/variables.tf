variable "name" {
  description = "Repository name."
  type        = string
}

variable "description" {
  description = "Repository description."
  type        = string
}

variable "visibility" {
  description = "Repository visibility."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "public", "internal"], var.visibility)
    error_message = "visibility must be private, public, or internal."
  }
}

variable "general" {
  description = "Common repository settings."
  type = object({
    default_branch         = optional(string, "main")
    auto_init              = optional(bool, true)
    has_issues             = optional(bool, true)
    has_discussions        = optional(bool, false)
    allow_merge_commit     = optional(bool, false)
    allow_rebase_merge     = optional(bool, false)
    allow_squash_merge     = optional(bool, true)
    delete_branch_on_merge = optional(bool, true)
  })
  default = {}
}

variable "maintainers" {
  description = "Team slugs granted maintain access."
  type        = set(string)
  default     = []
}

variable "writers" {
  description = "Team slugs granted push access."
  type        = set(string)
  default     = []
}

variable "environments" {
  description = "GitHub Environments to create."
  type        = set(string)
  default     = []
}

variable "default_branch_ruleset" {
  description = "Pull request requirements for the default branch. Set to null to disable the standard ruleset."
  type = object({
    required_approvals        = optional(number, 1)
    require_code_owner_review = optional(bool, true)
    required_status_checks    = optional(set(string), [])
  })
  default = {}
}
