# =====================================================================
# 🔐 EKS CONTROL PLANE IAM ROLE
# ---------------------------------------------------------------------
# This IAM role is assumed by the Amazon EKS control plane.
# It allows EKS to interact with AWS services like:
#   - EC2 (for network interfaces)
#   - ELB (for load balancers)
#   - CloudWatch Logs
#
# AWS-managed policies:
#   - AmazonEKSClusterPolicy
#   - AmazonEKSServicePolicy
#
# This role must exist before EKS cluster creation.
# =====================================================================

resource "aws_iam_role" "eks_cluster_role" {
  name = "EKSClusterRole"

  # ----------------------------------------------------------
  # 🧾 TRUST POLICY
  # ----------------------------------------------------------
  # Allows the EKS service to assume this role.
  # ----------------------------------------------------------
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "EKSClusterRole"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}


# ------------------------------------------------------------
# 📎 ATTACH REQUIRED POLICIES
# ------------------------------------------------------------
# AWS-managed IAM policies required for EKS control plane operation.
# ------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "eks_cluster_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  ])

  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = each.value
}


# ------------------------------------------------------------
# 📤 OUTPUT — CLUSTER ROLE ARN
# ------------------------------------------------------------
output "eks_cluster_role_arn" {
  description = "ARN of the IAM Role used by the EKS control plane."
  value       = aws_iam_role.eks_cluster_role.arn
}
