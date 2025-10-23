###############################################################
# 📤 MODULE OUTPUTS — ACCESS CONTROL MODULE
###############################################################

# 🔹 IAM USERS
output "iam_users" {
  description = "Map of IAM usernames to their ARNs (used for IAM trust and EKS access)."
  value       = try({ for username, user in aws_iam_user.users : username => user.arn }, {})
}

# 🔹 KUBERNETES NAMESPACES
output "kubernetes_namespaces" {
  description = "List of Kubernetes namespaces managed by this module."
  value       = try(keys(kubernetes_namespace.ns), [])
}

# 🔹 IAM ROLES (Cluster-level only)
output "iam_role_arns" {
  description = "Cluster-level IAM role ARNs for EKS access."
  value = merge(
    length(aws_iam_role.cluster_admin) > 0 ? { cluster_admin = aws_iam_role.cluster_admin[0].arn } : {},
    length(aws_iam_role.cluster_viewer) > 0 ? { cluster_viewer = aws_iam_role.cluster_viewer[0].arn } : {}
  )
}

# 🔹 EKS ACCESS ENTRIES (Cluster-level only)
output "eks_access_entries" {
  description = "EKS access entries for cluster-level IAM roles."
  value = merge(
    length(aws_eks_access_entry.role_cluster_admin) > 0 ? {
      cluster_admin = {
        arn               = aws_eks_access_entry.role_cluster_admin[0].principal_arn
        kubernetes_groups = aws_eks_access_entry.role_cluster_admin[0].kubernetes_groups
      }
    } : {},
    length(aws_eks_access_entry.role_cluster_viewer) > 0 ? {
      cluster_viewer = {
        arn               = aws_eks_access_entry.role_cluster_viewer[0].principal_arn
        kubernetes_groups = aws_eks_access_entry.role_cluster_viewer[0].kubernetes_groups
      }
    } : {}
  )
}
