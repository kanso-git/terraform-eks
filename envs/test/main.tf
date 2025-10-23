# =====================================================================
# ☸️ TEST ENVIRONMENT — MAIN TERRAFORM CONFIGURATION
# ---------------------------------------------------------------------
# Deploys a complete EKS environment including:
#   • VPC networking
#   • IAM role for EKS control plane
#   • EKS control plane and managed node groups
#   • Kubernetes add-ons (metrics-server, LBC, ingress, cert-manager)
#   • Safe dependency and cleanup ordering
# =====================================================================

############################################################
# 🕓 LOCALS
############################################################
locals {
  creation_date = formatdate("YYYY-MM-DD", timestamp())
}

############################################################
# 🧱 STAGE 1 — VPC
############################################################
module "vpc" {
  source = "../../modules/vpc"

  create_vpc           = true
  existing_vpc_id      = null
  vpc_cidr             = var.vpc_cidr
  cluster_name         = var.cluster_name
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  environment   = var.environment
  owner         = var.owner
  extra_tags    = var.extra_tags
  creation_date = local.creation_date
}

############################################################
# 🔐 STAGE 2 — IAM (Cluster Role)
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
# ☸️ STAGE 3 — EKS CLUSTER
############################################################
module "eks" {
  source = "../../modules/eks"

  cluster_name     = var.cluster_name
  cluster_version  = var.cluster_version
  cluster_role_arn = module.iam.eks_cluster_role_arn

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  node_groups        = var.node_groups

  enable_endpoint_public_access  = var.enable_endpoint_public_access
  enable_endpoint_private_access = var.enable_endpoint_private_access

  authentication_mode                         = var.authentication_mode
  bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions

  environment   = var.environment
  owner         = var.owner
  extra_tags    = var.extra_tags
  creation_date = local.creation_date

  depends_on = [module.vpc, module.iam]
}

############################################################
# 🕓 WAIT UNTIL EKS API IS READY (Deterministic + kubeconfig refresh)
############################################################
resource "null_resource" "wait_for_eks_ready" {
  provisioner "local-exec" {
    command = <<EOT
      set -euo pipefail

      CLUSTER="${var.cluster_name}"
      REGION="${var.aws_region}"

      echo "⏳ Waiting for EKS control plane '$CLUSTER' in $REGION to become ACTIVE…"
      aws eks wait cluster-active --name "$CLUSTER" --region "$REGION"
      echo "✅ Control plane is ACTIVE."

      echo "🔁 Refreshing local kubeconfig for '$CLUSTER'…"
      aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION" --alias "$CLUSTER" >/dev/null

      # Optional sanity check (won't fail the run if kubectl isn't configured)
      if command -v kubectl >/dev/null 2>&1; then
        echo "🔎 kubectl version (best effort)…"
        kubectl version --short || true
      fi

      echo "🕰  Giving the API endpoint time to stabilize (DNS/auth)…"
      sleep 90

      echo "✅ EKS API ready gate complete."
    EOT
  }

  # This gate runs strictly after the cluster exists
  depends_on = [module.eks]
}






############################################################
# 🔐 STAGE 4 — ACCESS CONTROL (IAM + RBAC)
############################################################
module "access" {
  source = "../../modules/access"

  providers = {
    aws        = aws
    kubernetes = kubernetes
  }

  aws_region   = var.aws_region
  environment  = var.environment
  cluster_name = module.eks.cluster_name

  namespaces             = var.namespaces
  cluster_viewer_users   = var.cluster_viewer_users
  namespace_viewer_users = var.namespace_viewer_users
  cluster_admin_users    = var.cluster_admin_users
  namespace_admin_users  = var.namespace_admin_users

  owner         = var.owner
  extra_tags    = var.extra_tags
  creation_date = local.creation_date

  depends_on = [null_resource.wait_for_eks_ready]
}

############################################################
# 📈 STAGE 5 — METRICS SERVER
############################################################
module "metrics_server" {
  source = "../../modules/addons/1-metrics-server"

  namespace     = "kube-system"
  chart_version = "3.12.1"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [null_resource.wait_for_eks_ready]
}

############################################################
# 🧩 STAGE 6 — EKS POD IDENTITY ADDON
############################################################
module "pod_identity" {
  source = "../../modules/addons/2-pod-identity"

  cluster_name = module.eks.cluster_name
  environment  = var.environment

  providers = {
    aws = aws
  }

  depends_on = [module.eks]
}

############################################################
# ⚙️ STAGE 7 — CLUSTER AUTOSCALER
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

  depends_on = [module.pod_identity, module.metrics_server]
}

############################################################
# 🌐 STAGE 8 — AWS LOAD BALANCER CONTROLLER
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
# 🌐 STAGE 9 — NGINX INGRESS CONTROLLER
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
# 🔐 STAGE 10 — CERT-MANAGER
############################################################
module "cert_manager" {
  source = "../../modules/addons/6-cert-manager"

  namespace     = "cert-manager"
  chart_version = "v1.15.0"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.nginx_ingress]
}

############################################################
# 💤 FINAL CLEANUP DELAY (Safe destroy)
############################################################
resource "time_sleep" "final_teardown_delay" {
  destroy_duration = "180s"
  depends_on = [
    module.cert_manager,
    module.nginx_ingress,
    module.aws_load_balancer_controller,
    module.cluster_autoscaler,
    module.metrics_server
  ]
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
