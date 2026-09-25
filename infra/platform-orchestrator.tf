# Platform Orchestrator Provider
provider "platform-orchestrator" {
  org_id     = var.orchestrator_org
  auth_token = var.orchestrator_auth_token
  api_url    = var.orchestrator_api_url
}

# Shared Kubernetes Provider (cloud-agnostic)
resource "platform-orchestrator_provider" "k8s" {
  deletion_policy    = "retain"
  id                 = "default"
  description        = "Provider using default runner environment variables for Kubernetes"
  provider_type      = "kubernetes"
  source             = "hashicorp/kubernetes"
  version_constraint = "~> 2.38.0"
  configuration      = jsonencode({})
}

# Shared Helm Provider (cloud-agnostic)
resource "platform-orchestrator_provider" "helm" {
  deletion_policy    = "retain"
  id                 = "default"
  description        = "Provider using default runner environment variables for Helm"
  provider_type      = "helm"
  source             = "hashicorp/helm"
  version_constraint = "~> 3.0.2"
  configuration      = jsonencode({})
}

# Shared Ansible Provider (cloud-agnostic)
resource "platform-orchestrator_provider" "ansibleplay" {
  deletion_policy    = "retain"
  id                 = "default"
  description        = "Platform Orchestrator provider for Ansible playbooks"
  provider_type      = "ansibleplay"
  source             = "humanitec/ansibleplay"
  version_constraint = "~> 0.3.2"
  configuration      = jsonencode({})
}

# Shared Resource Type: K8s Namespace (cloud-agnostic)
resource "platform-orchestrator_resource_type" "k8s_namespace" {
  deletion_policy = "retain"
  id              = "k8s-namespace"
  description     = "A Kubernetes namespace"
  output_schema = jsonencode({
    type = "object"
    properties = {
      namespace = {
        type = "string"
      }
    }
  })
  is_developer_accessible = true
  depends_on              = [platform-orchestrator_provider.k8s]
}

resource "platform-orchestrator_module_catalogue_entry" "k8s_namespace" {
  id            = "k8s-namespace"
  resource_type = platform-orchestrator_resource_type.k8s_namespace.id
  description   = "Module for a Kubernetes namespace"
}

resource "platform-orchestrator_module_version" "k8s_namespace" {
  module_id         = platform-orchestrator_module_catalogue_entry.k8s_namespace.id
  semantic_version  = "1.0.0"
  lifecycle_status  = "default"
  transition_reason = "Make the tutorial baseline available for first deployment"
  definition = jsonencode({
    module_source = "git::https://github.com/stellwerk-labs/first-deployment//modules/k8s-namespace?ref=4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
    output_schema = {
      type       = "object"
      properties = { namespace = { type = "string" } }
    }
    module_params = {}
    module_inputs = {}
    provider_mapping = {
      kubernetes = "kubernetes.default"
    }
    dependencies    = {}
    coprovisioned   = []
    source_revision = "4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
  })
  depends_on = [platform-orchestrator_provider.k8s, platform-orchestrator_provider.helm, platform-orchestrator_provider.ansibleplay]
}

resource "platform-orchestrator_module_rule" "k8s_namespace" {
  module_id  = platform-orchestrator_module_catalogue_entry.k8s_namespace.id
  depends_on = [platform-orchestrator_module_version.k8s_namespace]
}

# Shared Resource Type: In-Cluster Postgres (cloud-agnostic)
resource "platform-orchestrator_resource_type" "in_cluster_postgres" {
  deletion_policy = "retain"
  id              = "postgres"
  description     = "An in-cluster Postgres database using CloudNativePG"
  output_schema = jsonencode({
    type = "object"
    properties = {
      hostname = {
        type = "string"
      }
      port = {
        type = "integer"
      }
      database = {
        type = "string"
      }
      username = {
        type = "string"
      }
      password = {
        type = "string"
      }
    }
  })
  is_developer_accessible = true
  depends_on              = [platform-orchestrator_provider.k8s]
}

resource "platform-orchestrator_module_catalogue_entry" "in_cluster_postgres" {
  id            = "in-cluster-postgres"
  resource_type = platform-orchestrator_resource_type.in_cluster_postgres.id
}

resource "platform-orchestrator_module_version" "in_cluster_postgres" {
  module_id         = platform-orchestrator_module_catalogue_entry.in_cluster_postgres.id
  semantic_version  = "1.0.0"
  lifecycle_status  = "default"
  transition_reason = "Make the tutorial baseline available for first deployment"
  definition = jsonencode({
    module_source = "git::https://github.com/stellwerk-labs/first-deployment//modules/postgres?ref=4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
    output_schema = {
      type = "object"
      properties = {
        hostname = { type = "string" }
        port     = { type = "integer" }
        database = { type = "string" }
        username = { type = "string" }
        password = { type = "string" }
      }
    }
    module_params = {}
    module_inputs = {
      namespace = "$${resources.namespace.outputs.namespace}"
    }
    provider_mapping = {
      kubernetes = "kubernetes.default"
    }
    dependencies = {
      namespace = {
        type = platform-orchestrator_resource_type.k8s_namespace.id
        id   = "main"
      }
    }
    coprovisioned   = []
    source_revision = "4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
  })
  depends_on = [
    platform-orchestrator_provider.k8s
  ]
}

resource "platform-orchestrator_module_rule" "in_cluster_postgres" {
  module_id  = platform-orchestrator_module_catalogue_entry.in_cluster_postgres.id
  depends_on = [platform-orchestrator_module_version.in_cluster_postgres]
}

# Shared Resource Type: Score Workload
resource "platform-orchestrator_resource_type" "score_workload" {
  deletion_policy = "retain"
  id              = "score-workload"
  description     = "A workload that deploys a Score file"
  output_schema = jsonencode({
    type = "object"
    properties = {
      loadbalancer = {
        type = "string"
      }
    }
  })
  is_developer_accessible = true
  depends_on              = [platform-orchestrator_provider.helm, platform-orchestrator_provider.ansibleplay]
}

# Score Workload Module for Kubernetes
resource "platform-orchestrator_module_catalogue_entry" "score_k8s" {
  id            = "score-k8s"
  resource_type = platform-orchestrator_resource_type.score_workload.id
}

resource "platform-orchestrator_module_version" "score_k8s" {
  module_id         = platform-orchestrator_module_catalogue_entry.score_k8s.id
  semantic_version  = "1.0.0"
  lifecycle_status  = "default"
  transition_reason = "Make the tutorial baseline available for first deployment"
  definition = jsonencode({
    module_source = "git::https://github.com/stellwerk-labs/first-deployment//modules/score-workload/kubernetes?ref=4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
    output_schema = {
      type       = "object"
      properties = { loadbalancer = { type = "string" } }
    }
    module_params = {
      metadata = {
        type        = "map"
        description = "The metadata component of the Score workload"
      }
      containers = {
        type        = "map"
        description = "The containers component of the Score workload"
      }
      service = {
        type        = "map"
        is_optional = true
        description = "The service component of the Score workload"
      }
    }
    module_inputs = {
      namespace = "$${resources.ns.outputs.namespace}"
    }
    provider_mapping = {
      kubernetes = "kubernetes.default"
    }
    dependencies = {
      ns = {
        type = platform-orchestrator_resource_type.k8s_namespace.id
        id   = "main"
      }
    }
    coprovisioned   = []
    source_revision = "4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
  })
  depends_on = [platform-orchestrator_provider.k8s, platform-orchestrator_provider.helm, platform-orchestrator_provider.ansibleplay]
}

resource "platform-orchestrator_module_rule" "score_k8s" {
  module_id  = platform-orchestrator_module_catalogue_entry.score_k8s.id
  depends_on = [platform-orchestrator_module_version.score_k8s]
}

# VM Fleet Resource Type
resource "platform-orchestrator_resource_type" "vm_fleet" {
  deletion_policy = "retain"
  id              = "vm-fleet"
  description     = "A fleet of virtual machines"
  output_schema = jsonencode({
    type = "object"
    properties = {
      instance_ips = {
        type = "array"
        items = {
          type = "string"
        }
      }
      ssh_username = {
        type = "string"
      }
      ssh_private_key = {
        type = "string"
      }
      loadbalancer_ip = {
        type = "string"
      }
    }
  })
  is_developer_accessible = true
}

# Ansible Score Workload Module (for VM-based deployments)
resource "platform-orchestrator_module_catalogue_entry" "ansible_score_workload" {
  id            = "ansible-score-workload"
  resource_type = platform-orchestrator_resource_type.score_workload.id
}

resource "platform-orchestrator_module_version" "ansible_score_workload" {
  module_id         = platform-orchestrator_module_catalogue_entry.ansible_score_workload.id
  semantic_version  = "1.0.0"
  lifecycle_status  = "default"
  transition_reason = "Make the tutorial baseline available for first deployment"
  definition = jsonencode({
    module_source = "git::https://github.com/stellwerk-labs/first-deployment//modules/score-workload/ansible?ref=4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
    output_schema = {
      type       = "object"
      properties = { loadbalancer = { type = "string" } }
    }
    module_params = {
      metadata = {
        type        = "map"
        description = "The metadata component of the Score workload"
      }
      containers = {
        type        = "map"
        description = "The containers component of the Score workload"
      }
      service = {
        type        = "map"
        is_optional = true
        description = "The service component of the Score workload"
      }
    }
    module_inputs = {
      ips             = "$${resources.fleet.outputs.instance_ips}"
      loadbalancer    = "$${resources.fleet.outputs.loadbalancer_ip}"
      ssh_user        = "$${resources.fleet.outputs.ssh_username}"
      ssh_private_key = "$${resources.fleet.outputs.ssh_private_key}"
    }
    provider_mapping = {
      ansibleplay = "ansibleplay.default"
    }
    dependencies = {
      fleet = {
        type = platform-orchestrator_resource_type.vm_fleet.id
      }
    }
    coprovisioned   = []
    source_revision = "4b17d97474a6cdb51d4da1b42dd041f6d4e03aee"
  })
  depends_on = [platform-orchestrator_provider.k8s, platform-orchestrator_provider.helm, platform-orchestrator_provider.ansibleplay]
}

# Environment Type
resource "platform-orchestrator_environment_type" "environment_type" {
  id           = "${local.prefix}-development"
  display_name = "Development Environment"
}

# Project
resource "platform-orchestrator_project" "project" {
  id = "${local.prefix}-tutorial"
}

resource "platform-orchestrator_resource_type" "route_type" {
  deletion_policy         = "retain"
  id                      = "route"
  description             = "HTTP route resource type"
  is_developer_accessible = "true"
  output_schema = jsonencode({
    "type" : "object",
    "properties" : {}
  })
}

resource "platform-orchestrator_module_catalogue_entry" "route" {
  id            = "http-route"
  resource_type = platform-orchestrator_resource_type.route_type.id
}

resource "platform-orchestrator_module_version" "route" {
  module_id         = platform-orchestrator_module_catalogue_entry.route.id
  semantic_version  = "1.0.0"
  lifecycle_status  = "default"
  transition_reason = "Make the tutorial baseline available for first deployment"
  definition = jsonencode({
    module_source = "git::https://github.com/stellwerk-tf-modules/route-kubernetes-http-route?ref=907cf91be19c90be7633d74a08452eea486a6268"
    output_schema = {
      type       = "object"
      properties = {}
    }
    module_params = {
      hostname = {
        type = "string"
      }
      path = {
        type = "string"
      }
      service = {
        type = "string"
      }
      service_port = {
        type = "number"
      }
    }
    module_inputs = {
      namespace         = "$${resources.ns.outputs.namespace}"
      gateways          = ["default-gateway"]
      gateway_namespace = "envoy-gateway-system"
    }
    provider_mapping = {
      kubernetes = "kubernetes.default"
    }
    dependencies = {
      ns = {
        type = platform-orchestrator_resource_type.k8s_namespace.id
        id   = "main"
      }
    }
    coprovisioned   = []
    source_revision = "907cf91be19c90be7633d74a08452eea486a6268"
  })
  depends_on = [platform-orchestrator_provider.k8s]
}

resource "platform-orchestrator_module_rule" "route_module_rule" {
  module_id  = platform-orchestrator_module_catalogue_entry.route.id
  depends_on = [platform-orchestrator_module_version.route]
}
