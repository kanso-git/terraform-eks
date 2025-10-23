###########################################
# 📊 Metrics Server Helm Deployment
# ----------------------------------------
# Deploys the Kubernetes Metrics Server using Helm.
# Used by Kubernetes components like the HPA and dashboard
# to collect resource usage metrics (CPU, memory).
###########################################


resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = var.namespace
  version    = var.chart_version

  # Optional local values.yaml override (if it exists)
  values = [
    fileexists("${path.module}/values.yaml") ? file("${path.module}/values.yaml") : ""
  ]

  wait          = true
  recreate_pods = true
  timeout       = 600

  # Ensure Helm waits for all resources to become ready
  cleanup_on_fail = true
}
