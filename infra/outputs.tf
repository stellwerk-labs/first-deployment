# Common Outputs
output "prefix" {
  description = "Resource prefix used across all resources"
  value       = local.prefix
}

output "orchestrator_org" {
  description = "Platform Orchestrator organization ID"
  value       = var.orchestrator_org
}

output "project_id" {
  description = "Platform Orchestrator project ID"
  value       = platform-orchestrator_project.project.id
}
