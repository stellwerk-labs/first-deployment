# Runner namespace for this Azure cluster
resource "kubernetes_namespace" "runner" {
  metadata {
    name = "${var.prefix}-platform-orchestrator-runner"
  }

  timeouts {
    delete = "15m"
  }
}
