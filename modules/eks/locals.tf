#######################################################################
# ☸️ EKS MODULE — Locals
# ---------------------------------------------------------------------
# Consolidates dynamic values:
#  • Creation date fallback
#  • Node IAM role name fallback
#  • Subnet list for the cluster (private + public)
#  • Common tagging (env/owner/date + extra)
#######################################################################

locals {
  # 🕓 Creation date (prefer caller input, else auto-generate)
  creation_date = var.creation_date != "" ? var.creation_date : formatdate("YYYY-MM-DD", timestamp())

  # 🧾 Node role name (safe default per cluster)
  node_role_name = var.node_role_name != "" ? var.node_role_name : "${var.cluster_name}-node-role"

  # 🗺️ Subnets used by the control plane (include both for HA & ALB)
  cluster_subnet_ids = distinct(concat(var.private_subnet_ids, var.public_subnet_ids))

  # 🏷️ Tag sets
  base_tags = {
    Environment  = var.environment
    Owner        = var.owner
    CreationDate = local.creation_date
  }

  common_tags = merge(local.base_tags, var.extra_tags)
}
