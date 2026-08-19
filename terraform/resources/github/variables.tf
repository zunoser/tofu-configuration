variable "organization" {
  description = "GitHub organization login."
  type        = string
}

variable "users" {
  description = "Organization members managed by this stack."
  type = list(object({
    email    = string
    username = string
    role     = optional(string, "member")
  }))
  default = []

  validation {
    condition     = alltrue([for user in var.users : contains(["member", "admin"], user.role)])
    error_message = "user role must be member or admin."
  }

  validation {
    condition     = length(distinct([for user in var.users : user.username])) == length(var.users)
    error_message = "usernames must be unique."
  }
}

variable "teams" {
  description = "Organization teams keyed by team name."
  type = map(object({
    description = optional(string, "")
    privacy     = optional(string, "closed")
    members     = optional(set(string), [])
  }))
  default = {}
}
