# =====================================================================
# ☸️ TEST ENVIRONMENT — MAIN TERRAFORM CONFIGURATION
# ---------------------------------------------------------------------
# Deploys a complete EKS environment including:
#   • VPC networking
#   • IAM role for EKS control plane
#   • EKS control plane and managed node groups
#   • EKS access control (IAM roles, Kubernetes RBAC)
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
# 🔐 STAGE 4 — ACCESS CONTROL (IAM, EKS API, RBAC)
############################################################
module "access" {
  source = "../../modules/access"

  # Providers (explicit mapping keeps things clean)
  providers = {
    aws        = aws
    kubernetes = kubernetes
  }

  aws_region   = var.aws_region
  environment  = var.environment
  cluster_name = module.eks.cluster_name

  # Namespaces to create + RBAC apply scope
  namespaces = var.namespaces

  # User groups (deduped automatically in module)
  cluster_viewer_users   = var.cluster_viewer_users
  namespace_viewer_users = var.namespace_viewer_users
  cluster_admin_users    = var.cluster_admin_users
  namespace_admin_users  = var.namespace_admin_users

  owner         = var.owner
  extra_tags    = var.extra_tags
  creation_date = local.creation_date

  depends_on = [module.eks]
}

############################################################
# 📈 STAGE 5 — METRICS SERVER ADD-ON
############################################################
module "metrics_server" {
  source = "../../modules/addons/1-metrics-server"

  namespace     = "kube-system"
  chart_version = "3.12.1"

  providers = {
    helm        = helm
    kubernetes  = kubernetes
  }
  depends_on = [module.access]
}

############################################################
# 🧩 STAGE 6 — EKS Pod Identity Addon
############################################################
module "pod_identity" {
  source = "../../modules/addons/2-pod-identity"

  cluster_name = module.eks.cluster_name
  environment  = var.environment

  providers = {
    aws = aws
  }
  depends_on = [module.metrics_server]
}

############################################################
# ⚙️ STAGE 7 — Cluster Autoscaler (Helm)
############################################################
module "cluster_autoscaler" {
  source = "../../modules/addons/3-cluster-autoscaler"

  cluster_name = module.eks.cluster_name
  aws_region   = var.aws_region

  providers = {
    aws        = aws
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.pod_identity]
}


############################################################
# 🌐 STAGE 7 — AWS Load Balancer Controller
############################################################
module "aws_load_balancer_controller" {
  source = "../../modules/addons/4-aws-load-balancer-controller"

  cluster_name = module.eks.cluster_name
  aws_region   = var.aws_region
  vpc_id       = module.vpc.vpc_id

  providers = {
    aws        = aws
    kubernetes = kubernetes
    helm       = helm
  }
  depends_on = [module.cluster_autoscaler]
}

############################################################
# 🌐 STAGE 8 — NGINX Ingress Controller
############################################################
module "nginx_ingress" {
  source = "../../modules/addons/5-nginx-ingress"
  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
  depends_on = [module.aws_load_balancer_controller]
}


############################################################
# 🔐 STAGE 9 — cert-manager (Helm)
############################################################

module "cert_manager" {
  source = "../../modules/addons/6-cert-manager"

  namespace     = "cert-manager"
  chart_version = "v1.15.0"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  # Optional: if you prefer cert-manager only after ingress
  depends_on = [module.nginx_ingress]
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
