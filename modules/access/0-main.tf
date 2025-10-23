# =====================================================================
# 📦 Module: Access Control (EKS + IAM + RBAC)
# ---------------------------------------------------------------------
# Declares required providers for IAM, Kubernetes, and EKS integrations.
# Providers themselves are configured at the environment level.
# =====================================================================

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}
