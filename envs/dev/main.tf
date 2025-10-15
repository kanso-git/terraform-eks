# =====================================================================
# 🌐 DEVELOPMENT ENVIRONMENT — MAIN TERRAFORM CONFIGURATION
# ---------------------------------------------------------------------
# This file orchestrates all infrastructure components for the "dev"
# environment. It defines and connects modules in the correct order:
#
#   1. 🌍 VPC Module — creates the networking foundation.
#   2. ☸️ EKS Module — deploys the Kubernetes cluster on top of the VPC.
#
# Global variables and providers are defined externally (in `global/`),
# ensuring consistent configurations across environments (dev/test/prod).
#
# Executed commands:
#   terraform init -backend-config=backend.conf -reconfigure
#   terraform plan -var-file="dev.tfvars"
#   terraform apply -var-file="dev.tfvars"
# =====================================================================


############################################################
# ☁️ AWS Provider Configuration — Development
############################################################
# Defines the AWS provider and region for this environment.
# The provider must be declared at the root level, not in modules.
# ------------------------------------------------------------
provider "aws" {
  region  = "eu-central-2"      # Zurich region
  # profile = "terraform-mfa"   # Uncomment for local AWS CLI usage
}


############################################################
# 🌍 Global Configuration (Optional)
############################################################
# Imports shared settings from the `global` folder.
# This module provides:
#   - Global variables (region, profile, cluster_version)
#   - Any shared resources or defaults
############################################################
module "global" {
  source = "../../global"
}


# =====================================================================
# 🧱 STAGE 1 — VPC MODULE
# ---------------------------------------------------------------------
# Provisions a dedicated VPC with public and private subnets for EKS.
# Outputs from this module (VPC ID, subnets, tags) will be passed
# directly to the EKS module.
# =====================================================================
module "vpc" {
  source = "../../modules/vpc"

  # ----------------------------------------------------------
  # 🌍 Environment Metadata
  # ----------------------------------------------------------
  environment   = var.environment
  cluster_name  = var.cluster_name
  creation_date = var.creation_date

  # ----------------------------------------------------------
  # 🧱 Networking Configuration
  # ----------------------------------------------------------
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# =====================================================================
# 🔐 IAM MODULE — EKS CLUSTER ROLE
# ---------------------------------------------------------------------
# Creates the IAM role and policies required for the EKS control plane.
# This module must run before the EKS cluster module.
# =====================================================================
module "iam" {
  source = "../../modules/iam"
}

# =====================================================================
# ☸️ STAGE 2 — EKS MODULE
# ---------------------------------------------------------------------
# Deploys an Amazon EKS cluster within the newly created VPC.
# It uses:
#   - VPC outputs (for networking)
#   - Global settings (for version and region)
#   - Environment variables (for naming, tags)
#
# The EKS module handles:
#   - Cluster creation
#   - Node groups (scalable worker nodes)
#   - Security groups and IAM roles
#   - Tag propagation for cost tracking
# =====================================================================
module "eks" {
  source = "../../modules/eks"

  # ----------------------------------------------------------
  # ☸️ Cluster Core Settings
  # ----------------------------------------------------------
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version



  # ----------------------------------------------------------
  # 🧱 Networking — Linked from the VPC module
  # ----------------------------------------------------------
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  
  # ----------------------------------------------------------
  # 🔐 IAM & Role Configuration
  # ----------------------------------------------------------
  # Use the dynamically created IAM role from the IAM module
  cluster_role_arn = module.iam.eks_cluster_role_arn


  # ----------------------------------------------------------
  # 🧑‍💻 Node Group Settings
  # ----------------------------------------------------------
  # Map of node group configurations (instance type, scaling, etc.)
  node_groups = var.node_groups

  # ----------------------------------------------------------
  # 🏷️ Tagging & Traceability
  # ----------------------------------------------------------
  # Combine base tags from the VPC with any environment-specific tags.
  tags = merge(module.vpc.base_tags, var.extra_tags)
}
