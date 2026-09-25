# Platform Orchestrator Provider for Azure
resource "platform-orchestrator_provider" "azurerm" {
  deletion_policy    = "retain"
  id                 = "default"
  description        = "Provider for Azure using service principal or managed identity"
  provider_type      = "azurerm"
  source             = "hashicorp/azurerm"
  version_constraint = "~> 4.46"
  configuration = jsonencode(merge(
    {
      "features[0]"   = {}
      subscription_id = var.azure_subscription_id
      tenant_id       = var.azure_tenant_id
    },
    var.azure_client_id != "" ? {
      client_id     = var.azure_client_id
      client_secret = var.azure_client_secret
      } : {
      use_cli                   = false
      use_aks_workload_identity = true
    }
  ))
}

# VM Fleet Module for Azure
resource "platform-orchestrator_module_catalogue_entry" "vm_fleet" {
  id            = "vm-fleet-azure"
  resource_type = var.vm_fleet_resource_type_id # Reference from root to create dependency
}

resource "platform-orchestrator_module_version" "vm_fleet" {
  module_id         = platform-orchestrator_module_catalogue_entry.vm_fleet.id
  semantic_version  = "1.0.0"
  lifecycle_status  = "default"
  transition_reason = "Make the tutorial baseline available for first deployment"
  definition = jsonencode({
    module_source = "git::https://github.com/stellwerk-labs/first-deployment//modules/vm-fleet/azure?ref=4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
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
      azurerm = "azurerm.default"
    }
    dependencies    = {}
    coprovisioned   = []
    source_revision = "4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
  })
  depends_on = [
    platform-orchestrator_provider.azurerm # Ensure Azure provider exists first
  ]
}

resource "platform-orchestrator_module_rule" "vm_fleet" {
  module_id = platform-orchestrator_module_catalogue_entry.vm_fleet.id

  depends_on = [
    platform-orchestrator_module_version.vm_fleet
  ]
}
