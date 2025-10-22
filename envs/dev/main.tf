# =====================================================================
# ☸️ DEV ENVIRONMENT — MAIN TERRAFORM CONFIGURATION
# ---------------------------------------------------------------------
# Deploys a complete EKS environment including:
#   • VPC networking
#   • IAM role for EKS control plane
#   • EKS control plane and managed node groups
#
# Modules are reusable and environment-scoped (dev, test, prod).
# =====================================================================

############################################################
# 🕓 LOCALS
############################################################
# Compute a dynamic creation date once at runtime.
############################################################
locals {
  creation_date = formatdate("YYYY-MM-DD", timestamp())
}

############################################################
# 🧱 STAGE 1 — VPC
############################################################
module "vpc" {
  source = "../../modules/vpc"

  # Networking
  create_vpc           = true
  existing_vpc_id      = null
  vpc_cidr             = var.vpc_cidr
  cluster_name         = var.cluster_name
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  # Metadata & tagging
  environment   = var.environment
  owner         = var.owner
  extra_tags    = var.extra_tags
  creation_date = local.creation_date
}

############################################################
# 🔐 STAGE 2 — IAM
############################################################
module "iam" {
  source            = "../../modules/iam"
  cluster_role_name = "EKSClusterRole-${var.environment}"

  environment   = var.environment
  owner         = var.owner
  extra_tags    = var.extra_tags
  creation_date = local.creation_date
}

############################################################
# ☸️ STAGE 3 — EKS
############################################################
module "eks" {
  source = "../../modules/eks"

  cluster_name     = var.cluster_name
  cluster_version  = var.cluster_version
  cluster_role_arn = module.iam.eks_cluster_role_arn

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  node_groups = var.node_groups

  environment   = var.environment
  owner         = var.owner
  extra_tags    = var.extra_tags
  creation_date = local.creation_date

  enable_endpoint_public_access  = var.enable_endpoint_public_access
  enable_endpoint_private_access = var.enable_endpoint_private_access

  # EKS access control
  authentication_mode                         = var.authentication_mode
  bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
}

############################################################
# 📤 OUTPUTS
############################################################
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
