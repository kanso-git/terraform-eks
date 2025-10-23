# =====================================================================
# 🧮 LOCAL COMPUTATIONS — ACCESS CONTROL MODULE
# ---------------------------------------------------------------------
# Purpose:
#   Compute all derived values for IAM, EKS, and RBAC integration:
#     • Normalize user input (flat or per-namespace)
#     • Generate Kubernetes group names
#     • Compute per-user → group memberships
#     • Tagging metadata and creation date
#
# Supports:
#   - Cluster-level admin/viewer access
#   - Namespace-level admin/viewer access
#   - Backward-compatible flat list input format
# =====================================================================

locals {

  # -------------------------------------------------------------------
  # 🕓 CREATION DATE
  # -------------------------------------------------------------------
  # If no explicit creation date is passed, generate the current date
  # (YYYY-MM-DD). This is used for tagging AWS resources consistently.
  # -------------------------------------------------------------------
  creation_date = (
    var.creation_date != "" ?
    var.creation_date :
    formatdate("YYYY-MM-DD", timestamp())
  )


  # -------------------------------------------------------------------
  # 🏷️ TAGGING METADATA — BASE & COMMON TAGS
  # -------------------------------------------------------------------
  # Merges base environment, owner, and creation metadata
  # with optional custom `extra_tags` provided by the caller.
  # -------------------------------------------------------------------
  base_tags = {
    Environment  = var.environment
    Owner        = var.owner
    CreationDate = local.creation_date
  }

  common_tags = merge(local.base_tags, var.extra_tags)


  # -------------------------------------------------------------------
  # 🔹 NORMALIZE NAMESPACE USER INPUTS
  # -------------------------------------------------------------------
  # Input types supported:
  #   Option A: map(namespace → list of users)
  #   Option B: flat list (applied to all namespaces)
  #
  # Output type: map(string → list(string))
  # -------------------------------------------------------------------
  normalized_namespace_viewer_users = (
    can(keys(var.namespace_viewer_users))
    ? tomap({
      for ns, users in var.namespace_viewer_users :
      ns => tolist(users)
    })
    : tomap({
      for ns in var.namespaces :
      ns => tolist(try(var.namespace_viewer_users, []))
    })
  )

  normalized_namespace_admin_users = (
    can(keys(var.namespace_admin_users))
    ? tomap({
      for ns, users in var.namespace_admin_users :
      ns => tolist(users)
    })
    : tomap({
      for ns in var.namespaces :
      ns => tolist(try(var.namespace_admin_users, []))
    })
  )


  # -------------------------------------------------------------------
  # 👥 ALL USERS — DEDUPLICATED SET
  # -------------------------------------------------------------------
  # Builds the complete set of IAM usernames from all sources:
  #   - Cluster admins/viewers
  #   - Namespace admins/viewers
  #
  # Output type: set(string)
  # -------------------------------------------------------------------
  all_users = toset(flatten(concat(
    var.cluster_admin_users,
    var.cluster_viewer_users,
    flatten(values(local.normalized_namespace_admin_users)),
    flatten(values(local.normalized_namespace_viewer_users))
  )))


  # -------------------------------------------------------------------
  # ☸️ KUBERNETES RBAC GROUP NAMING
  # -------------------------------------------------------------------
  # These group names are used by aws_eks_access_entry to connect
  # IAM roles to Kubernetes RBAC roles.
  #
  # Example conventions:
  #   Cluster Admin  → rbac:cluster:admin
  #   Cluster Viewer → rbac:cluster:viewer
  #   Namespace Admin  → rbac:ns:<namespace>:admin
  #   Namespace Viewer → rbac:ns:<namespace>:viewer
  # -------------------------------------------------------------------
  k8s_groups = {
    cluster_admin  = "rbac:cluster:admin"
    cluster_viewer = "rbac:cluster:viewer"
  }

  ns_admin_groups = {
    for ns in var.namespaces : ns => "rbac:ns:${ns}:admin"
  }

  ns_viewer_groups = {
    for ns in var.namespaces : ns => "rbac:ns:${ns}:viewer"
  }


  # -------------------------------------------------------------------
  # 🧩 USER → KUBERNETES GROUP MEMBERSHIPS
  # -------------------------------------------------------------------
  # Produces map(user → list(K8s groups)) for all cluster
  # and namespace access levels.
  #
  # Example output:
  # {
  #   "alice" = ["rbac:cluster:admin", "rbac:ns:dev:admin"]
  #   "bob"   = ["rbac:cluster:viewer", "rbac:ns:test:viewer"]
  # }
  # -------------------------------------------------------------------
  user_k8s_groups = {
    for user in local.all_users : user => concat(
      # Cluster-level memberships
      contains(var.cluster_admin_users, user) ? [local.k8s_groups.cluster_admin] : [],
      contains(var.cluster_viewer_users, user) ? [local.k8s_groups.cluster_viewer] : [],

      # Namespace Admin groups
      flatten([
        for ns, users in local.normalized_namespace_admin_users :
        contains(users, user) && contains(var.namespaces, ns)
        ? [local.ns_admin_groups[ns]]
        : []
      ]),

      # Namespace Viewer groups
      flatten([
        for ns, users in local.normalized_namespace_viewer_users :
        contains(users, user) && contains(var.namespaces, ns)
        ? [local.ns_viewer_groups[ns]]
        : []
      ])
    )
  }


  # -------------------------------------------------------------------
  # 🧾 ADDITIONAL POLICY CONTROL FLAG
  # -------------------------------------------------------------------
  # Helper flag used later in IAM role/policy logic to determine
  # if `eks:DescribeCluster` should be granted to users.
  # -------------------------------------------------------------------
  include_eks_describe_cluster = var.add_eks_describe_cluster_permission

}
