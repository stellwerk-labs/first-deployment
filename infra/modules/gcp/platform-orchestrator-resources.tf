# Platform Orchestrator Provider for Google
resource "platform-orchestrator_provider" "google" {
  deletion_policy    = "retain"
  id                 = "default"
  description        = "Provider using default runner environment variables for Google"
  provider_type      = "google"
  source             = "hashicorp/google"
  version_constraint = "~> 4.74"
  configuration = jsonencode({
    region      = var.gcp_region
    zone        = var.gcp_zone
    project     = var.gcp_project_id
    credentials = "/providers/google-service-account/credentials.json"
  })
}

# Resource Type: GCS Bucket
resource "platform-orchestrator_resource_type" "bucket" {
  deletion_policy = "retain"
  id              = "bucket"
  description     = "A bucket in Google Cloud Storage"
  output_schema = jsonencode({
    type = "object"
    properties = {
      name = {
        type = "string"
      }
    }
  })
  is_developer_accessible = true

  depends_on = [platform-orchestrator_provider.google]
}

# Module: GCS Bucket
resource "platform-orchestrator_module_catalogue_entry" "bucket" {
  id            = "gcs-bucket"
  resource_type = platform-orchestrator_resource_type.bucket.id
  description   = "Module for a Google Cloud Storage bucket"
}

resource "platform-orchestrator_module_version" "bucket" {
  module_id         = platform-orchestrator_module_catalogue_entry.bucket.id
  semantic_version  = "1.0.0"
  lifecycle_status  = "default"
  transition_reason = "Make the tutorial baseline available for first deployment"
  definition = jsonencode({
    module_source = "git::https://github.com/stellwerk-labs/first-deployment//modules/bucket?ref=4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
    output_schema = {
      type       = "object"
      properties = { name = { type = "string" } }
    }
    module_params = {}
    module_inputs = {
      google_storage_bucket_name = "${var.prefix}-first-deployment-bucket"
    }
    provider_mapping = {
      google = "google.default"
    }
    dependencies    = {}
    coprovisioned   = []
    source_revision = "4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
  })
  depends_on = [
    platform-orchestrator_provider.google # Ensure Google provider exists first
  ]
}

resource "platform-orchestrator_module_rule" "bucket" {
  module_id = platform-orchestrator_module_catalogue_entry.bucket.id

  depends_on = [
    platform-orchestrator_module_version.bucket
  ]
}

# Resource Type: Pub/Sub Queue
resource "platform-orchestrator_resource_type" "queue" {
  deletion_policy = "retain"
  id              = "queue"
  description     = "A queue in Google Cloud Pub/Sub"
  output_schema = jsonencode({
    type = "object"
    properties = {
      name = {
        type = "string"
      }
    }
  })
  is_developer_accessible = true

  depends_on = [platform-orchestrator_provider.google]
}

# Module: Pub/Sub Topic
resource "platform-orchestrator_module_catalogue_entry" "queue" {
  id            = "pub-sub-topic"
  resource_type = platform-orchestrator_resource_type.queue.id
  description   = "Module for a Google Cloud Pub/Sub topic"
}

resource "platform-orchestrator_module_version" "queue" {
  module_id         = platform-orchestrator_module_catalogue_entry.queue.id
  semantic_version  = "1.0.0"
  lifecycle_status  = "default"
  transition_reason = "Make the tutorial baseline available for first deployment"
  definition = jsonencode({
    module_source = "git::https://github.com/stellwerk-labs/first-deployment//modules/pub-sub-topic?ref=4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
    output_schema = {
      type       = "object"
      properties = { name = { type = "string" } }
    }
    module_params = {}
    module_inputs = {
      topic_name = "${var.prefix}-first-deployment-topic"
    }
    provider_mapping = {
      google = "google.default"
    }
    dependencies    = {}
    coprovisioned   = []
    source_revision = "4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
  })
  depends_on = [platform-orchestrator_provider.google]
}

resource "platform-orchestrator_module_rule" "queue" {
  module_id = platform-orchestrator_module_catalogue_entry.queue.id

  depends_on = [
    platform-orchestrator_module_version.queue
  ]
}

# Resource Type: K8s Service Account (GCP-specific with workload identity)
resource "platform-orchestrator_resource_type" "k8s_service_account" {
  deletion_policy = "retain"
  id              = "k8s-service-account"
  description     = "A Kubernetes service account"
  output_schema = jsonencode({
    type = "object"
    properties = {
      service_account_name = {
        type = "string"
      }
    }
  })
  is_developer_accessible = true
  depends_on              = [platform-orchestrator_provider.google]
}

# Module: K8s Service Account (GCP-specific)
# TODO: This module is using a hardcoded GCP service account email, we should create a module and use it here as dependency
resource "platform-orchestrator_module_catalogue_entry" "k8s_service_account" {
  id            = "k8s-service-account"
  resource_type = platform-orchestrator_resource_type.k8s_service_account.id
  description   = "Module for a Kubernetes service account"
}

resource "platform-orchestrator_module_version" "k8s_service_account" {
  module_id         = platform-orchestrator_module_catalogue_entry.k8s_service_account.id
  semantic_version  = "1.0.0"
  lifecycle_status  = "default"
  transition_reason = "Make the tutorial baseline available for first deployment"
  definition = jsonencode({
    module_source = "git::https://github.com/stellwerk-labs/first-deployment//modules/k8s-service-account?ref=4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
    output_schema = {
      type       = "object"
      properties = { service_account_name = { type = "string" } }
    }
    module_params = {}
    module_inputs = {
      gcp_service_account_email = "htc-demo-00@htc-demo-00-gcp.iam.gserviceaccount.com"
      namespace                 = "$${resources.namespace.outputs.namespace}"
      project_id                = var.gcp_project_id
    }
    provider_mapping = {
      kubernetes = "kubernetes.default"
      google     = "google.default"
    }
    dependencies = {
      namespace = {
        type = "k8s-namespace"
        id   = "main"
      }
    }
    coprovisioned   = []
    source_revision = "4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
  })
  depends_on = [
    platform-orchestrator_provider.google # Ensure Google provider exists first
  ]
}

resource "platform-orchestrator_module_rule" "k8s_service_account" {
  module_id = platform-orchestrator_module_catalogue_entry.k8s_service_account.id

  depends_on = [
    platform-orchestrator_module_version.k8s_service_account
  ]
}

# VM Fleet Module for GCP
resource "platform-orchestrator_module_catalogue_entry" "vm_fleet" {
  id            = "vm-fleet-gcp"
  resource_type = var.vm_fleet_resource_type_id # Reference from root to create dependency
}

resource "platform-orchestrator_module_version" "vm_fleet" {
  module_id         = platform-orchestrator_module_catalogue_entry.vm_fleet.id
  semantic_version  = "1.0.0"
  lifecycle_status  = "default"
  transition_reason = "Make the tutorial baseline available for first deployment"
  definition = jsonencode({
    module_source = "git::https://github.com/stellwerk-labs/first-deployment//modules/vm-fleet/google?ref=4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
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
      google = "google.default"
    }
    dependencies    = {}
    coprovisioned   = []
    source_revision = "4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
  })
  depends_on = [
    platform-orchestrator_provider.google # Ensure Google provider exists first
  ]
}

resource "platform-orchestrator_module_rule" "vm_fleet" {
  module_id = platform-orchestrator_module_catalogue_entry.vm_fleet.id

  depends_on = [
    platform-orchestrator_module_version.vm_fleet
  ]
}
