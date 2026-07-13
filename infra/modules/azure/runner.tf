# Call the shared runner integration module
module "runner" {
  source = "../shared/runner-integration"

  prefix                            = var.prefix
  orchestrator_org                  = var.orchestrator_org
  runner_namespace                  = kubernetes_namespace.runner.metadata[0].name
  runner_service_account_name       = "${var.prefix}-platform-orchestrator-runner-sa"
  runner_inner_service_account_name = "${var.prefix}-platform-orchestrator-runner-sa-inner"
  cloud_provider                    = "azure"
  public_key_pem                    = var.public_key_pem
  private_key_pem                   = var.private_key_pem

  # Azure-specific configuration
  azure_client_id       = azurerm_user_assigned_identity.platform_orchestrator_runner.client_id
  azure_tenant_id       = var.azure_tenant_id
  azure_subscription_id = var.azure_subscription_id

  depends_on = [
    azurerm_kubernetes_cluster.cluster,
    azurerm_user_assigned_identity.platform_orchestrator_runner,
    azurerm_federated_identity_credential.platform_orchestrator_runner,
    kubernetes_namespace.runner
  ]
}
