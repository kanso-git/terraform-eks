# =====================================================================
# 🔐 ACCESS MODULE — IAM ROLES + TRUST + EKS ACCESS + USER POLICIES
# =====================================================================

locals {
  cluster_admin_role_name  = "${var.cluster_name}-cluster-admin"
  cluster_viewer_role_name = "${var.cluster_name}-cluster-viewer"
}

# ---------------------- TRUST POLICIES ----------------------

data "aws_iam_policy_document" "trust_cluster_admin" {
  count = length(var.cluster_admin_users) > 0 ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [for u in var.cluster_admin_users : aws_iam_user.users[u].arn]
    }
  }
}

data "aws_iam_policy_document" "trust_cluster_viewer" {
  count = length(var.cluster_viewer_users) > 0 ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [for u in var.cluster_viewer_users : aws_iam_user.users[u].arn]
    }
  }
}

# ---------------------- IAM ROLES ----------------------

resource "aws_iam_role" "cluster_admin" {
  count              = length(var.cluster_admin_users) > 0 ? 1 : 0
  name               = local.cluster_admin_role_name
  assume_role_policy = data.aws_iam_policy_document.trust_cluster_admin[0].json
}

resource "aws_iam_role" "cluster_viewer" {
  count              = length(var.cluster_viewer_users) > 0 ? 1 : 0
  name               = local.cluster_viewer_role_name
  assume_role_policy = data.aws_iam_policy_document.trust_cluster_viewer[0].json
}

# ---------------------- EKS ACCESS ENTRIES ----------------------

resource "aws_eks_access_entry" "role_cluster_admin" {
  count             = length(var.cluster_admin_users) > 0 ? 1 : 0
  cluster_name      = var.cluster_name
  principal_arn     = aws_iam_role.cluster_admin[0].arn
  kubernetes_groups = [local.k8s_groups.cluster_admin]
}

resource "aws_eks_access_entry" "role_cluster_viewer" {
  count             = length(var.cluster_viewer_users) > 0 ? 1 : 0
  cluster_name      = var.cluster_name
  principal_arn     = aws_iam_role.cluster_viewer[0].arn
  kubernetes_groups = [local.k8s_groups.cluster_viewer]
}

# ---------------------- USER POLICIES ----------------------

data "aws_caller_identity" "current" {}

locals {
  cluster_admin_role_arn  = try(aws_iam_role.cluster_admin[0].arn, null)
  cluster_viewer_role_arn = try(aws_iam_role.cluster_viewer[0].arn, null)
}

resource "aws_iam_user_policy" "allow_assume_roles" {
  for_each = { for u in local.all_users : u => u }

  user = aws_iam_user.users[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAssumeAllowedRoles"
        Effect = "Allow"
        Action = ["sts:AssumeRole"]
        Resource = flatten([
          local.cluster_admin_role_arn != null ? [local.cluster_admin_role_arn] : [],
          local.cluster_viewer_role_arn != null ? [local.cluster_viewer_role_arn] : []
        ])
      },
      {
        Sid      = "AllowDescribeEKSCluster"
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
      }
    ]
  })
}
