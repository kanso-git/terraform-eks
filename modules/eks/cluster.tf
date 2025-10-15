# =====================================================================
# ☸️ EKS CLUSTER RESOURCE DEFINITION
# ---------------------------------------------------------------------
# This file provisions the Amazon EKS (Elastic Kubernetes Service)
# control plane for the current environment.
#
# The EKS cluster acts as the Kubernetes control plane managed by AWS.
# It uses:
#   - VPC ID and subnet IDs (from the VPC module)
#   - IAM role for EKS (provided via variable)
#   - Cluster version (to define Kubernetes version)
#   - Tags for resource traceability and ownership
#
# AWS will automatically manage:
#   - Control plane nodes (highly available masters)
#   - Cluster endpoint
#   - EKS API access and certificate authority
#
# NOTE:
#   The cluster does *not* include worker nodes here; they are
#   defined separately in `node_groups.tf`.
# =====================================================================


############################################################
# ☸️ AWS EKS CLUSTER
############################################################
# The core EKS control plane definition.
# This creates:
#   - The managed Kubernetes control plane
#   - API server endpoint
#   - CA certificate authority
#   - Control-plane security group (managed by AWS)
############################################################
resource "aws_eks_cluster" "this" {
  # ----------------------------------------------------------
  # 🏷️ CLUSTER NAME AND VERSION
  # ----------------------------------------------------------
  name     = var.cluster_name       # e.g., "eks-dev-cluster"
  version  = var.cluster_version    # e.g., "1.33"

  # ----------------------------------------------------------
  # 🔐 CLUSTER IAM ROLE
  # ----------------------------------------------------------
  # This IAM role allows EKS to manage AWS resources such as
  # EC2 instances, Elastic Load Balancers, and CloudWatch Logs.
  # It must have the AWS-managed EKS policies attached:
  #   - AmazonEKSClusterPolicy
  #   - AmazonEKSServicePolicy
  # ----------------------------------------------------------
  role_arn = var.cluster_role_arn

  # ----------------------------------------------------------
  # 🌐 NETWORKING CONFIGURATION
  # ----------------------------------------------------------
  # The cluster must be deployed in the same VPC as the worker
  # nodes. These subnets (private and public) define where EKS
  # control plane network interfaces (ENIs) will be placed.
  # ----------------------------------------------------------
  vpc_config {
    subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids)

    # Controls whether the API server is reachable publicly.
    # - true  => accessible via Internet
    # - false => private-only endpoint
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  # ----------------------------------------------------------
  # 🏷️ TAGS
  # ----------------------------------------------------------
  # Tags are merged at the environment level to include both
  # base (from VPC) and extra environment-specific tags.
  # These tags will appear in the AWS console for all EKS-related
  # resources (e.g., ENIs, security groups, logs).
  # ----------------------------------------------------------
  tags = merge(
    {
      Name        = var.cluster_name
      Environment = "dev"
      ManagedBy   = "Terraform"
    },
    var.tags
  )

  # ----------------------------------------------------------
  # ⚙️ DEPENDENCIES
  # ----------------------------------------------------------
  # Ensure EKS is created only after the VPC and its subnets exist.
  # This prevents race conditions where AWS cannot locate the subnets.
  # ----------------------------------------------------------
  depends_on = [
    var.vpc_id
  ]
}


############################################################
# 📦 DATA SOURCE — EKS CLUSTER INFO
############################################################
# Used to fetch connection details once the cluster is created:
#   - API endpoint
#   - Certificate authority data
#   - Cluster name (for kubectl/Helm providers)
############################################################
data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.this.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.this.name
}


############################################################
# 🧾 OUTPUT — CLUSTER DETAILS
############################################################
# These outputs are helpful for external modules (like Helm
# or Kubernetes providers) to connect to this cluster.
############################################################
output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint URL."
  value       = data.aws_eks_cluster.eks.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded EKS certificate authority data."
  value       = data.aws_eks_cluster.eks.certificate_authority[0].data
}
