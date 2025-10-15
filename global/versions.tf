############################################################
# 📦 Terraform & Provider Version Constraints
# ----------------------------------------------------------
# This file ensures compatibility across all modules and
# keeps versions pinned to stable, production-ready releases.
############################################################

terraform {
  # Require Terraform 1.13.x or newer (latest stable)
  required_version = ">= 1.13.0"

  required_providers {
    # AWS provider for all AWS resources (EKS, IAM, VPC, etc.)
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.16" # latest stable branch
    }

    # Kubernetes provider for managing cluster resources
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33" # compatible with EKS 1.33
    }

    # Helm provider for managing Helm charts inside EKS
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13" # latest stable as of 2025
    }

    # Optional: null provider (used for triggers or templates)
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    # Optional: random provider (used for unique naming)
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
