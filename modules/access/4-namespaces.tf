##########################################
# 🧩 Kubernetes Namespaces
# ----------------------------------------
# Creates one namespace per entry in var.namespaces.
##########################################

resource "kubernetes_namespace" "ns" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.key
    labels = {
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}
