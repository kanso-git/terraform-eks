# =====================================================================
# 📤 OUTPUTS — VPC MODULE
# ---------------------------------------------------------------------
# Defines all exported values from the VPC module.
# These outputs are consumed by other Terraform modules (e.g., EKS, RDS)
# or directly referenced at the environment level.
#
# Includes:
# - VPC ID (new or existing)
# - Subnet IDs (public/private)
# - Route table and gateway IDs
# - Optional tagging info
# =====================================================================

# ------------------------------------------------------------
# 🧱 VPC ID
# ------------------------------------------------------------
# The main VPC identifier (newly created or reused).
# Used by EKS, RDS, or any resource requiring VPC context.
# ------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC (either newly created or reused)."
  value       = local.vpc_id
}

# ------------------------------------------------------------
# 🌐 Public Subnet IDs
# ------------------------------------------------------------
# All public subnets created by the module.
# Used for ALBs, NLBs, or NAT Gateway placement.
# ------------------------------------------------------------
output "public_subnet_ids" {
  description = "List of all public subnet IDs created for this VPC."
  value       = [for s in aws_subnet.public : s.id]
}

# ------------------------------------------------------------
# 🔒 Private Subnet IDs
# ------------------------------------------------------------
# All private subnets created by the module.
# Typically used for EKS node groups and private workloads.
# ------------------------------------------------------------
output "private_subnet_ids" {
  description = "List of all private subnet IDs created for this VPC."
  value       = [for s in aws_subnet.private : s.id]
}

# ------------------------------------------------------------
# 🛣️ Route Table IDs
# ------------------------------------------------------------
# Public and private route tables for subnet association
# or route extensions (e.g., peering, transit gateway).
# ------------------------------------------------------------
output "public_route_table_id" {
  description = "ID of the public route table (used by public subnets)."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table (used by private subnets)."
  value       = aws_route_table.private.id
}

# ------------------------------------------------------------
# 🌍 Internet Gateway ID
# ------------------------------------------------------------
# Exports the IGW ID attached to this VPC.
# Required for public subnets or NAT internet routing.
# ------------------------------------------------------------
output "internet_gateway_id" {
  description = "The ID of the Internet Gateway attached to the VPC."
  value       = aws_internet_gateway.this.id
}

# ------------------------------------------------------------
# ☁️ NAT Gateway ID
# ------------------------------------------------------------
# Exports the NAT Gateway used for private subnet internet access.
# Typically needed when debugging or connecting VPC endpoints.
# ------------------------------------------------------------
output "nat_gateway_id" {
  description = "The ID of the NAT Gateway associated with this VPC."
  value       = aws_nat_gateway.this.id
}

# ------------------------------------------------------------
# 🏷️ VPC Tags (Optional)
# ------------------------------------------------------------
# Exports the base tagging pattern for traceability.
# NOTE: You can build this in locals if needed later.
# ------------------------------------------------------------
output "base_tags" {
  description = "Common static tags for traceability."
  value = {
    Environment  = var.environment
    Owner        = var.owner
    CreationDate = var.creation_date
  }
}
