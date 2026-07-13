moved {
  from = azurerm_user_assigned_identity.humanitec_runner
  to   = azurerm_user_assigned_identity.platform_orchestrator_runner
}

moved {
  from = azurerm_role_assignment.humanitec_aksmi_contributor
  to   = azurerm_role_assignment.platform_orchestrator_aksmi_contributor
}

moved {
  from = azurerm_role_assignment.humanitec_runner_contributor
  to   = azurerm_role_assignment.platform_orchestrator_runner_contributor
}

moved {
  from = azurerm_federated_identity_credential.humanitec_runner
  to   = azurerm_federated_identity_credential.platform_orchestrator_runner
}
