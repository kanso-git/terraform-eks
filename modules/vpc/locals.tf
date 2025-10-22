#######################################################################
# 🌐 VPC MODULE — Locals
# ---------------------------------------------------------------------
# Centralizes computed values for the VPC module:
#  - Creation date fallback
#  - Active VPC ID (new or existing)
#  - Deterministic subnet maps for public/private subnets
#  - First public AZ for NAT placement (deterministic)
#  - Common tag map (env/owner/date + extra)
#######################################################################

locals {
  # 🕓 Creation date (compute if empty)
  creation_date = var.creation_date != "" ? var.creation_date : formatdate("YYYY-MM-DD", timestamp())

  # 🔗 Active VPC ID (created or existing)
  vpc_id = var.create_vpc ? aws_vpc.this[0].id : var.existing_vpc_id

  # 🗺️ Subnet maps (AZ -> CIDR)
  subnets = {
    public  = { for idx, az in var.azs : az => var.public_subnet_cidrs[idx] }
    private = { for idx, az in var.azs : az => var.private_subnet_cidrs[idx] }
  }

  # 🧭 Deterministic ordering for picking a public subnet (NAT)
  first_public_az = sort(keys(local.subnets.public))[0]

  # 🏷️ Base + merged tags
  base_tags = {
    Environment  = var.environment
    Owner        = var.owner
    CreationDate = local.creation_date
  }

  common_tags = merge(local.base_tags, var.extra_tags)
}
