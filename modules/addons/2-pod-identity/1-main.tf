

############################################################
# 🧩 EKS Pod Identity Addon
# ----------------------------------------------------------
# Deploys AWS EKS Pod Identity Agent as an official managed
# addon. Required for modern IAM-to-Pod associations.
############################################################

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name  = var.cluster_name
  addon_name    = "eks-pod-identity-agent"
  addon_version = var.addon_version

  tags = {
    "Name"        = "${var.cluster_name}-pod-identity-agent"
    "Environment" = var.environment
    "ManagedBy"   = "Terraform"
  }
}
