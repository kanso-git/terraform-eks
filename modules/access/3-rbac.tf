##########################################
# 📘 Kubernetes RBAC Configuration
# ----------------------------------------
# Creates ClusterRoles, Roles, and RoleBindings
# for both cluster-wide and namespace-scoped groups.
##########################################

# -------------------------------
# Cluster Roles
# -------------------------------

resource "kubernetes_cluster_role" "cluster_viewer" {
  metadata {
    name   = "cluster-viewer"
    labels = { managed_by = "terraform" }
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "configmaps", "namespaces"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "list", "watch"]
  }
}

# -------------------------------
# Cluster Role Bindings
# -------------------------------

resource "kubernetes_cluster_role_binding" "cluster_admin" {
  metadata {
    name   = "cluster-admin-binding"
    labels = { managed_by = "terraform" }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind = "Group"
    name = "rbac:cluster:admin"
  }
}

resource "kubernetes_cluster_role_binding" "cluster_viewer" {
  metadata {
    name   = "cluster-viewer-binding"
    labels = { managed_by = "terraform" }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cluster_viewer.metadata[0].name
  }

  subject {
    kind = "Group"
    name = "rbac:cluster:viewer"
  }
}

# -------------------------------
# Namespace Roles and Bindings
# -------------------------------
# Ensure these resources wait for the namespace creation
# (defined in 4-namespaces.tf as kubernetes_namespace.ns)
# -------------------------------

resource "kubernetes_role" "ns_admin" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "${each.key}-admin"
    namespace = each.key
    labels = {
      managed_by  = "terraform"
      environment = var.environment
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  depends_on = [kubernetes_namespace.ns] # ✅ Wait until namespace exists
}

resource "kubernetes_role" "ns_viewer" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "${each.key}-viewer"
    namespace = each.key
    labels = {
      managed_by  = "terraform"
      environment = var.environment
    }
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [kubernetes_namespace.ns] # ✅ Wait until namespace exists
}

resource "kubernetes_role_binding" "ns_admin" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "${each.key}-admin-binding"
    namespace = each.key
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.ns_admin[each.key].metadata[0].name
  }

  subject {
    kind = "Group"
    name = "rbac:ns:${each.key}:admin"
  }

  depends_on = [kubernetes_namespace.ns] # ✅ Wait until namespace exists
}

resource "kubernetes_role_binding" "ns_viewer" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "${each.key}-viewer-binding"
    namespace = each.key
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.ns_viewer[each.key].metadata[0].name
  }

  subject {
    kind = "Group"
    name = "rbac:ns:${each.key}:viewer"
  }

  depends_on = [kubernetes_namespace.ns] # ✅ Wait until namespace exists
}
