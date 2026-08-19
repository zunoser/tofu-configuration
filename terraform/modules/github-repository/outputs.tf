output "name" {
  description = "Managed repository name."
  value       = github_repository.this.name
}

output "full_name" {
  description = "Managed repository full name."
  value       = github_repository.this.full_name
}

output "node_id" {
  description = "Managed repository GraphQL node ID."
  value       = github_repository.this.node_id
}
