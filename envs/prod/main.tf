# =====================================================================
# 🌐 Production Environment — VPC Deployment
# ---------------------------------------------------------------------
# Provisions a dedicated and secure VPC for the EKS Prod cluster.
# =====================================================================

module "vpc" {
  source = "../../modules/vpc"

  environment          = var.environment
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}
