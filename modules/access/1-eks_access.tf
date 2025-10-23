##########################################
# ☸️ EKS (API mode) Access Entries
# ----------------------------------------
# - Maps each IAM User → Kubernetes Groups
# - Uses aws_eks_access_entry for fine-grained EKS identity access
##########################################

resource "aws_eks_access_entry" "user_entry" {
  for_each = local.all_users

  cluster_name      = var.cluster_name
  principal_arn     = aws_iam_user.users[each.key].arn
  kubernetes_groups = distinct(local.user_k8s_groups[each.key])

  tags = merge(local.common_tags, {
    Name      = "${var.cluster_name}-user-${each.key}-access"
    ManagedBy = "Terraform"
    Purpose   = "EKS-API-Auth"
  })
}
