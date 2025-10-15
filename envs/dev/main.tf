# =====================================================================
# 🌐 Development Environment — VPC Deployment
# ---------------------------------------------------------------------
# This file deploys the VPC module for the "dev" environment.
# It provisions:
#   - One dedicated VPC in the Zurich region (eu-central-2)
#   - Three public and three private subnets (for EKS)
#   - NAT Gateway, Internet Gateway, and route tables
#
# The module uses variables defined in dev.tfvars and the shared module files.
# =====================================================================


############################################################
# ☁️ AWS Provider Configuration — Development
############################################################
provider "aws" {
  region  = "eu-central-2"
  # profile = "terraform-mfa"
}

############################################################
# 🌍 Global Configuration (Optional)
############################################################
module "global" {
  source = "../../global"
}

module "vpc" {
  # ----------------------------------------------------------
  # 📦 Module Source
  # ----------------------------------------------------------
  source = "../../modules/vpc"

  # ----------------------------------------------------------
  # 🌍 Environment Configuration
  # ----------------------------------------------------------
  environment  = var.environment     # e.g. "dev"
  cluster_name = var.cluster_name    # e.g. "eks-dev-cluster"
  creation_date = var.creation_date  # e.g. "2024-01-01"

  # ----------------------------------------------------------
  # 🧱 Networking Configuration
  # ----------------------------------------------------------
  vpc_cidr             = var.vpc_cidr              # e.g. "10.0.0.0/16"
  azs                  = var.azs                   # e.g. ["eu-central-2a", "eu-central-2b", "eu-central-2c"]
  public_subnet_cidrs  = var.public_subnet_cidrs   # 3 public subnets
  private_subnet_cidrs = var.private_subnet_cidrs  # 3 private subnets
}
