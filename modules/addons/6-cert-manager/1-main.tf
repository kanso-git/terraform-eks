# =====================================================================
# cert-manager — Terraform Module (Stable & Safe Cleanup)
# =====================================================================

############################################################
# 🧱 Namespace
############################################################
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "cert-manager"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

############################################################
# 📦 Helm Release
############################################################
resource "helm_release" "cert_manager" {
  name             = var.release_name
  repository       = var.repository
  chart            = var.chart
  namespace        = kubernetes_namespace.cert_manager.metadata[0].name
  version          = var.chart_version
  create_namespace = false
  timeout          = 600

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [kubernetes_namespace.cert_manager]
}

############################################################
# 🧹 CRD Cleanup (destroy-only)
############################################################
resource "null_resource" "cleanup_cert_manager_crds" {
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "🧹 Deleting cert-manager CRDs (if any remain)..."
      if kubectl version --short >/dev/null 2>&1; then
        for crd in \
          certificaterequests.cert-manager.io \
          certificates.cert-manager.io \
          challenges.acme.cert-manager.io \
          clusterissuers.cert-manager.io \
          issuers.cert-manager.io \
          orders.acme.cert-manager.io; do
          echo "Deleting CRD: $crd"
          kubectl delete crd "$crd" --ignore-not-found
        done
        echo "✅ CRD cleanup complete."
      else
        echo "⚠️ Kubernetes API not reachable, skipping CRD cleanup."
      fi
    EOT
  }

  depends_on = [helm_release.cert_manager]
}

############################################################
# 🧹 Namespace Finalizer Cleanup (destroy-only)
############################################################
resource "null_resource" "cleanup_cert_manager_ns" {
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      NS="cert-manager"
      echo "🧹 Cleaning up namespace finalizers for $NS..."
      if kubectl version --short >/dev/null 2>&1; then
        if kubectl get ns "$NS" >/dev/null 2>&1; then
          kubectl get ns "$NS" -o json | jq 'del(.spec.finalizers)' | \
          kubectl replace --raw "/api/v1/namespaces/$NS/finalize" -f - || true
          echo "✅ Finalizers removed for namespace $NS."
        else
          echo "⚠️ Namespace $NS not found. Skipping."
        fi
      else
        echo "⚠️ Kubernetes API not reachable. Skipping namespace cleanup."
      fi
    EOT
  }

  depends_on = [null_resource.cleanup_cert_manager_crds]
}

############################################################
# ⏳ Sleep (allow K8s to catch up)
############################################################
resource "time_sleep" "wait_for_cert_manager_cleanup" {
  destroy_duration = "90s"
  depends_on       = [null_resource.cleanup_cert_manager_ns]
}
