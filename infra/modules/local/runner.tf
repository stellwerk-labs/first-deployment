# Call the shared runner integration module
module "runner" {
  source = "../shared/runner-integration"

  prefix                            = var.prefix
  orchestrator_org                  = var.orchestrator_org
  runner_namespace                  = kubernetes_namespace.runner.metadata[0].name
  runner_service_account_name       = "${var.prefix}-platform-orchestrator-runner-sa"
  runner_inner_service_account_name = "${var.prefix}-platform-orchestrator-runner-sa-inner"
  cloud_provider                    = "local"
  public_key_pem                    = var.public_key_pem
  private_key_pem                   = var.private_key_pem

  depends_on = [
    null_resource.kind_cluster,
    kubernetes_namespace.runner
  ]
}
