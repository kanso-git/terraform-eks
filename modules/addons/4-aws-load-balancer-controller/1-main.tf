# =====================================================================
# AWS Load Balancer Controller — Stable Terraform Module
# =====================================================================

# --- IAM Role Trust Policy for AWS Load Balancer Controller ---
data "aws_iam_policy_document" "aws_load_balancer_controller_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

# --- IAM Role ---
resource "aws_iam_role" "aws_load_balancer_controller" {
  name               = "${var.cluster_name}-aws-lbc-role"
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_trust.json
}

# --- IAM Policy (from JSON file) ---
resource "aws_iam_policy" "aws_lbc" {
  name   = "AWSLoadBalancerController"
  policy = file("${path.module}/iam-policy.json")
}

# --- Attach Policy to Role ---
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_lbc.arn
}

# --- Pod Identity Association ---
resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_load_balancer_controller.arn

  depends_on = [
    aws_iam_role_policy_attachment.aws_load_balancer_controller_attach
  ]
}

# --- Helm Chart Deployment ---
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.1"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  timeout = 900

  depends_on = [
    aws_eks_pod_identity_association.aws_load_balancer_controller
  ]
}

# --- Optional delay to ensure cleanup on destroy ---
resource "time_sleep" "wait_for_lbc_cleanup" {
  destroy_duration = "120s"
  depends_on       = [helm_release.aws_load_balancer_controller]
}
