# =====================================================================
# 🔐 IAM MODULE — EKS Control Plane Role
# ---------------------------------------------------------------------
# Creates the IAM role required by the EKS control plane and attaches
# the AWS-managed policies it needs to operate.
#
# This module is parameterized for reusability across environments.
# It dynamically computes the creation date if none is provided.
# =====================================================================

#######################################################################
# 🔐 IAM ROLE
#######################################################################
resource "aws_iam_role" "eks_cluster_role" {
  name = var.cluster_role_name

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

  tags = merge(local.common_tags, {
    Name = var.cluster_role_name
  })
}

#######################################################################
# 📎 POLICY ATTACHMENTS
#######################################################################
# Attaches the required AWS-managed IAM policies that allow EKS to
# interact with EC2, ELB, and other dependent services.
#######################################################################
resource "aws_iam_role_policy_attachment" "eks_cluster_policies" {
  for_each = toset(var.attach_policies)

  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = each.value
}

#######################################################################
# 📤 OUTPUTS
#######################################################################
output "eks_cluster_role_arn" {
  description = "ARN of the IAM role used by the EKS control plane. Used as cluster_role_arn in EKS module."
  value       = aws_iam_role.eks_cluster_role.arn
}
