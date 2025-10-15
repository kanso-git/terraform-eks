# =====================================================================
# ⚙️ LOCALS — VPC MODULE
# ---------------------------------------------------------------------
# Centralizes computed values and reusable logic for the VPC module.
#
# Includes:
# - Logic to determine whether to reuse or create a VPC
# - Pre-computed subnet maps for public/private subnet generation
# - Common tagging scheme (merged with optional user-defined tags)
# =====================================================================

# ------------------------------------------------------------
# 🧩 Determine Active VPC ID
# ------------------------------------------------------------
# If the user provides an existing VPC ID, we reuse it.
# Otherwise, we reference the newly created VPC.
# ------------------------------------------------------------
locals {
  vpc_id = var.vpc_id != null ? var.vpc_id : aws_vpc.this[0].id
}

# ------------------------------------------------------------
# 🏷️ Common Tags for All Resources
# ------------------------------------------------------------
# Provides a unified tagging convention for the entire module.
# Merges base tags with any extra tags provided by the user.
# ------------------------------------------------------------
locals {
  common_tags = merge(
    {
      Environment  = var.environment,                         # dev/test/prod
      Owner        = var.owner,                               # Ownership metadata
      CreationDate = var.creation_date != "" ? var.creation_date : timestamp()                       # Passed via variable (static timestamp)
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"   # EKS cluster discovery tag
    },
    var.extra_tags                                             # Optional user-supplied tags
  )
}

# ------------------------------------------------------------
# 🗺️ Subnet Grouping (for readability)
# ------------------------------------------------------------
# Combines AZs and CIDRs into logical subnet maps.
# Used by aws_subnet resources in main.tf.
# ------------------------------------------------------------
locals {
  subnets = {
    public  = zipmap(var.azs, var.public_subnet_cidrs)        # AZ-to-CIDR map for public subnets
    private = zipmap(var.azs, var.private_subnet_cidrs)       # AZ-to-CIDR map for private subnets
  }
}
