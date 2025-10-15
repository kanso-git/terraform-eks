############################################################
# ☁️ Global Provider Configuration
# ----------------------------------------------------------
# Defines global providers used across environments.
# Only the AWS provider is declared here, since it is
# required to create infrastructure (VPC, IAM, EKS).
#
# The Kubernetes and Helm providers depend on the EKS
# cluster and should be configured inside the EKS module
# after the cluster is created.
############################################################

provider "aws" {
  region  = var.aws_region
  # Optional: specify a named AWS CLI profile for local use
  # profile = var.aws_profile
}

# Note:
# - The kubernetes and helm providers will be configured
#   within the EKS module to avoid dependency errors.
