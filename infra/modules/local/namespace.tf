# Namespace for Platform Orchestrator runner
resource "kubernetes_namespace" "runner" {
  metadata {
    name = "${var.prefix}-platform-orchestrator-runner"
  }

  depends_on = [null_resource.wait_for_cluster]
}
