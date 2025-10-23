######################################################################
# ☸️ EKS MODULE — Multi-Environment Kubernetes on AWS
# -------------------------------------------------------------------
# Provisions:
#  • EKS control plane (versioned)
#  • API-based access_config (optional)
#  • Managed node groups (EC2) with a shared node IAM role
#
# Inputs come from env-level files (dev/test/prod). Tagging is unified
# via locals (environment, owner, creation_date + extra tags).
######################################################################

##############################
# ☸️ EKS CLUSTER
##############################
resource "aws_eks_cluster" "this" {
  name    = var.cluster_name
  version = var.cluster_version

  # IAM role for control plane (created in the IAM module)
  role_arn = var.cluster_role_arn

  # Networking: include both private + public for HA + ALB support
  vpc_config {
    subnet_ids              = local.cluster_subnet_ids
    endpoint_public_access  = var.enable_endpoint_public_access
    endpoint_private_access = var.enable_endpoint_private_access
  }

  # 🔐 Optional API-based access configuration (new EKS access model)
  dynamic "access_config" {
    for_each = var.authentication_mode != null ? [1] : []
    content {
      authentication_mode                         = var.authentication_mode
      bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
    }
  }

  tags = merge(local.common_tags, {
    Name      = var.cluster_name
    ManagedBy = "Terraform"
  })
}
