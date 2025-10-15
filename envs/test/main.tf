# =====================================================================
# 🌐 Test Environment — VPC Deployment
# ---------------------------------------------------------------------
# Provisions a dedicated VPC and subnets for the EKS Test cluster.
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
