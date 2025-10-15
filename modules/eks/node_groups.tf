# =====================================================================
# 🧩 EKS NODE GROUPS — MANAGED WORKER NODES
# ---------------------------------------------------------------------
# This file provisions Amazon EKS Managed Node Groups.
#
# Each node group represents a group of EC2 instances automatically
# managed by EKS. They connect to the EKS cluster created in `cluster.tf`
# and run workloads (Pods) scheduled by Kubernetes.
#
# Key Features:
#   - Fully managed lifecycle (EKS handles upgrades, scaling, health)
#   - Auto-scaling based on min/max/desired configuration
#   - Uses IAM roles for EC2 and Kubernetes worker permissions
#   - Deployed across multiple private subnets for HA
#
# Dependencies:
#   - EKS cluster must exist first
#   - VPC and subnets must be provisioned
#   - IAM role for node groups must have required policies
# =====================================================================


############################################################
# 🔐 IAM ROLE FOR NODE GROUPS
############################################################
# This IAM role allows EC2 worker nodes to:
#   - Connect to the EKS control plane
#   - Pull images from ECR
#   - Interact with CloudWatch Logs
#
# It must include the following AWS-managed policies:
#   - AmazonEKSWorkerNodePolicy
#   - AmazonEKS_CNI_Policy
#   - AmazonEC2ContainerRegistryReadOnly
#
# NOTE:
#   This example creates a role for all node groups to share.
#   You can customize per-group if desired.
############################################################
resource "aws_iam_role" "eks_nodes" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.cluster_name}-node-role"
      Environment = "dev"
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}


############################################################
# 🧩 IAM ROLE POLICY ATTACHMENTS
############################################################
# Attach AWS-managed policies required for EKS nodes.
############################################################
resource "aws_iam_role_policy_attachment" "eks_nodes_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  policy_arn = each.value
  role       = aws_iam_role.eks_nodes.name
}


############################################################
# ☸️ EKS MANAGED NODE GROUPS
############################################################
# Creates one managed node group per entry in var.node_groups.
#
# Each node group:
#   - Joins the EKS cluster automatically
#   - Uses the EC2 instance types and scaling config defined in dev.tfvars
#   - Distributes instances across private subnets for HA
#
# Example var.node_groups:
#   node_groups = {
#     general = {
#       desired_capacity = 2
#       min_size         = 1
#       max_size         = 3
#       instance_types   = ["t3.medium"]
#     }
#   }
############################################################
resource "aws_eks_node_group" "managed" {
  for_each = var.node_groups

  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids

  # ----------------------------------------------------------
  # 🧠 Scaling Configuration
  # ----------------------------------------------------------
  scaling_config {
    desired_size = each.value.desired_capacity
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  # ----------------------------------------------------------
  # ⚙️ Instance Configuration
  # ----------------------------------------------------------
  instance_types = each.value.instance_types

  # ----------------------------------------------------------
  # 🏷️ Tagging
  # ----------------------------------------------------------
  tags = merge(
    {
      Name        = "${var.cluster_name}-${each.key}-nodes"
      Environment = "dev"
      ManagedBy   = "Terraform"
    },
    var.tags
  )

  # ----------------------------------------------------------
  # ⚙️ Dependencies
  # ----------------------------------------------------------
  depends_on = [
    aws_eks_cluster.this
  ]
}


############################################################
# 📤 OUTPUTS — NODE GROUP DETAILS
############################################################
# These outputs expose useful details for external reference.
# Example use cases:
#   - Logging EC2 nodes
#   - Attaching monitoring agents
#   - Linking auto-scaling policies
############################################################
output "node_group_names" {
  description = "List of all EKS managed node group names."
  value       = [for ng in aws_eks_node_group.managed : ng.node_group_name]
}

output "node_group_arns" {
  description = "List of ARNs for all EKS managed node groups."
  value       = [for ng in aws_eks_node_group.managed : ng.arn]
}

output "node_iam_role_arn" {
  description = "IAM role ARN used by EKS worker nodes."
  value       = aws_iam_role.eks_nodes.arn
}
