# Platform Orchestrator Provider for AWS
resource "platform-orchestrator_provider" "aws" {
  deletion_policy    = "retain"
  id                 = "default"
  description        = "Provider using mounted credentials for AWS"
  provider_type      = "aws"
  source             = "hashicorp/aws"
  version_constraint = "~> 5.0"
  configuration = jsonencode({
    region                   = var.aws_region
    shared_credentials_files = ["/mnt/aws-creds/credentials"]
  })
}

# VM Fleet Module for AWS
resource "platform-orchestrator_module_catalogue_entry" "vm_fleet" {
  id            = "vm-fleet-aws"
  resource_type = var.vm_fleet_resource_type_id # Reference from root to create dependency
}

resource "platform-orchestrator_module_version" "vm_fleet" {
  module_id         = platform-orchestrator_module_catalogue_entry.vm_fleet.id
  semantic_version  = "1.0.0"
  lifecycle_status  = "default"
  transition_reason = "Make the tutorial baseline available for first deployment"
  definition = jsonencode({
    module_source = "git::https://github.com/stellwerk-labs/first-deployment//modules/vm-fleet/aws?ref=4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
    output_schema = {
      type = "object"
      properties = {
        instance_ips    = { type = "array", items = { type = "string" } }
        ssh_username    = { type = "string" }
        ssh_private_key = { type = "string" }
        loadbalancer_ip = { type = "string" }
      }
    }
    module_params = {}
    module_inputs = {}
    provider_mapping = {
      aws = "aws.default"
    }
    dependencies    = {}
    coprovisioned   = []
    source_revision = "4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
  })
  depends_on = [
    platform-orchestrator_provider.aws # Ensure AWS provider exists first
  ]
}

resource "platform-orchestrator_module_rule" "vm_fleet" {
  module_id = platform-orchestrator_module_catalogue_entry.vm_fleet.id

  depends_on = [
    platform-orchestrator_module_version.vm_fleet
  ]
}
