# =====================================================================
# NGINX Ingress Controller — Terraform Module (Stable with Safe Cleanup)
# =====================================================================

# --- Namespace ---
resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# --- Helm Release ---
resource "helm_release" "nginx_ingress" {
  name       = var.release_name
  repository = var.repository
  chart      = "ingress-nginx"
  namespace  = var.namespace
  version    = var.chart_version

  create_namespace = false
  timeout          = 600

  # Use provided values file or fallback to default
  values = var.values_file != null ? [file(var.values_file)] : [file("${path.module}/values.yaml")]

  depends_on = [
    kubernetes_namespace.nginx_ingress
  ]
}

# --- Namespace Finalizer Cleanup (Prevents stuck deletion) ---
resource "null_resource" "cleanup_nginx_ns" {
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      NS="ingress"
      echo "🧹 Removing namespace finalizers for $NS..."
      if kubectl get ns $NS >/dev/null 2>&1; then
        kubectl get ns $NS -o json | jq 'del(.spec.finalizers)' | \
        kubectl replace --raw "/api/v1/namespaces/$NS/finalize" -f - || true
      fi
    EOT
  }

  depends_on = [helm_release.nginx_ingress]
}

# --- Delay to ensure Kubernetes finalizes cleanup ---
resource "time_sleep" "wait_for_ingress_cleanup" {
  destroy_duration = "90s"
  depends_on       = [null_resource.cleanup_nginx_ns]
}
