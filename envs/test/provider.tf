# =====================================================================
# 📦 Terraform & Provider Version Constraints
# ---------------------------------------------------------------------
# Defines provider versions for AWS, Kubernetes, Helm, and supporting
# utilities. Ensures all environments use the same stable versions.
# =====================================================================

terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.16"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Default AWS provider configuration
provider "aws" {
  region = var.aws_region
}


# =====================================================================
# ☸️ Kubernetes Provider Configuration
# ---------------------------------------------------------------------
# This connects Terraform to the EKS cluster created by the eks module.
# Using module outputs ensures Terraform waits until the cluster exists.
# =====================================================================

# Only used to get a short-lived authentication token for EKS
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# Kubernetes provider uses EKS module outputs
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# Helm provider — for chart installations
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}