terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
    platform-orchestrator = {
      source  = "stellwerk-labs/platform-orchestrator"
      version = "~> 2.0"
    }
  }
}

# Deploy Platform Orchestrator Kubernetes Agent Runner using Helm chart
resource "kubernetes_secret_v1" "runner_identity" {
  metadata {
    name      = "${var.prefix}-runner-identity"
    namespace = var.runner_namespace
  }
  data = { "private-key.pem" = var.private_key_pem }
}

resource "kubernetes_secret_v1" "gateway_ca" {
  count = var.orchestrator_ca_pem == "" ? 0 : 1
  metadata {
    name      = "${var.prefix}-orchestrator-ca"
    namespace = var.runner_namespace
  }
  data = { "ca.crt" = var.orchestrator_ca_pem }
}

resource "helm_release" "platform_orchestrator_runner" {
  name       = "${var.prefix}-platform-orchestrator-runner"
  repository = "oci://ghcr.io/stellwerk-labs/charts"
  chart      = "platform-orchestrator-kubernetes-agent-runner"
  version    = "0.3.0"

  namespace        = var.runner_namespace
  create_namespace = false

  recreate_pods = true
  force_update  = true

  values = [
    yamlencode({
      platformOrchestrator = {
        orgId    = var.orchestrator_org
        runnerId = "${var.prefix}-first-deployment-agent-runner"
        logLevel = "info"
      }

      gateway = {
        mode                     = "simple"
        url                      = "${trimsuffix(var.orchestrator_api_url, "/")}/runner-gateway"
        privateKeyExistingSecret = kubernetes_secret_v1.runner_identity.metadata[0].name
        caExistingSecret         = try(kubernetes_secret_v1.gateway_ca[0].metadata[0].name, "")
        jobCaExistingSecret      = try(kubernetes_secret_v1.gateway_ca[0].metadata[0].name, "")
      }

      rbac = {
        create = true
      }

      jobsRbac = {
        create             = true
        serviceAccountName = var.runner_inner_service_account_name
        namespace          = var.runner_namespace
      }

      serviceAccount = {
        create = true
        name   = var.runner_service_account_name
      }
    })
  ]

  depends_on = [platform-orchestrator_kubernetes_agent_runner.agent_runner]
}

# ClusterRoleBinding for inner runner - ensure cluster-admin permissions
resource "kubernetes_cluster_role_binding" "runner_inner_cluster_admin" {
  metadata {
    name = "${var.prefix}-platform-orchestrator-runner-inner-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.runner_inner_service_account_name
    namespace = var.runner_namespace
  }

  depends_on = [helm_release.platform_orchestrator_runner]
}

# AWS IRSA - Add annotations after Helm chart creation
resource "kubernetes_annotations" "aws_irsa_sa" {
  count = var.cloud_provider == "aws" ? 1 : 0

  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = var.runner_service_account_name
    namespace = var.runner_namespace
  }

  annotations = {
    "eks.amazonaws.com/role-arn" = var.aws_iam_role_arn
  }

  depends_on = [helm_release.platform_orchestrator_runner]
}

# Azure Workload Identity - Add annotations and labels after Helm chart creation
resource "kubernetes_annotations" "azure_workload_identity_sa" {
  count = var.cloud_provider == "azure" ? 1 : 0

  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = var.runner_inner_service_account_name
    namespace = var.runner_namespace
  }

  annotations = {
    "azure.workload.identity/client-id" = var.azure_client_id
  }

  depends_on = [helm_release.platform_orchestrator_runner]
}

resource "kubernetes_labels" "azure_workload_identity_sa" {
  count = var.cloud_provider == "azure" ? 1 : 0

  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = var.runner_inner_service_account_name
    namespace = var.runner_namespace
  }

  labels = {
    "azure.workload.identity/use" = "true"
  }

  depends_on = [helm_release.platform_orchestrator_runner]
}

# Build volume mounts based on cloud provider
locals {
  volume_mounts = concat(
    var.cloud_provider == "aws" && var.aws_credentials_secret_name != null ? [{
      name      = "aws-creds"
      mountPath = "/mnt/aws-creds"
      readOnly  = true
    }] : [],
    var.cloud_provider == "gcp" && var.gcp_service_account_secret_name != null ? [{
      name      = "google-service-account"
      mountPath = "/providers/google-service-account"
      readOnly  = true
    }] : [],
    var.cloud_provider == "azure" && var.azure_client_id != null ? [{
      name      = "azure-identity-token"
      mountPath = "/var/run/secrets/azure/tokens"
      readOnly  = true
    }] : []
  )

  volumes = concat(
    var.cloud_provider == "aws" && var.aws_credentials_secret_name != null ? [{
      name = "aws-creds"
      secret = {
        secretName = var.aws_credentials_secret_name
      }
    }] : [],
    var.cloud_provider == "gcp" && var.gcp_service_account_secret_name != null ? [{
      name = "google-service-account"
      secret = {
        secretName = var.gcp_service_account_secret_name
      }
    }] : [],
    var.cloud_provider == "azure" && var.azure_client_id != null ? [{
      name = "azure-identity-token"
      projected = {
        sources = [{
          serviceAccountToken = {
            path              = "azure-identity-token"
            audience          = "api://AzureADTokenExchange"
            expirationSeconds = 3600
          }
        }]
      }
    }] : []
  )

  # Environment variables for cloud provider authentication
  env_vars = var.cloud_provider == "azure" && var.azure_client_id != null ? [
    {
      name  = "AZURE_CLIENT_ID"
      value = var.azure_client_id
    },
    {
      name  = "AZURE_TENANT_ID"
      value = var.azure_tenant_id
    },
    {
      name  = "AZURE_SUBSCRIPTION_ID"
      value = var.azure_subscription_id
    },
    {
      name  = "AZURE_FEDERATED_TOKEN_FILE"
      value = "/var/run/secrets/azure/tokens/azure-identity-token"
    }
  ] : []

  pod_metadata = var.cloud_provider == "azure" ? {
    labels = {
      "azure.workload.identity/use" = "true"
    }
  } : {}
}

# Platform Orchestrator Runner Configuration
resource "platform-orchestrator_kubernetes_agent_runner" "agent_runner" {
  id = "${var.prefix}-first-deployment-agent-runner"
  runner_configuration = {
    key = var.public_key_pem
    job = {
      namespace       = var.runner_namespace
      service_account = var.runner_inner_service_account_name
      service_account_annotations = var.cloud_provider == "azure" && var.azure_client_id != null ? {
        "azure.workload.identity/client-id" = var.azure_client_id
      } : {}
      pod_template = jsonencode({
        metadata = local.pod_metadata
        spec = {
          containers = [{
            name         = "main"
            env          = local.env_vars
            volumeMounts = local.volume_mounts
            securityContext = {
              runAsNonRoot             = false,
              runAsUser                = 0,
              runAsGroup               = 0,
              privileged               = true,
              allowPrivilegeEscalation = true
            }
          }]
          volumes = local.volumes
        }
      })
    }
  }
  state_storage_configuration = {
    type = "kubernetes"
    kubernetes_configuration = {
      namespace = var.runner_namespace
    }
  }
}

# Runner rule
resource "platform-orchestrator_runner_rule" "agent_runner_rule" {
  runner_id = platform-orchestrator_kubernetes_agent_runner.agent_runner.id
}
