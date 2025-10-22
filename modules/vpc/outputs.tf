#######################################################################
# 📤 OUTPUTS — VPC MODULE
# ---------------------------------------------------------------------
# Export values consumed by other modules (EKS, RDS, etc.)
#######################################################################

output "vpc_id" {
  description = "The ID of the VPC (either newly created or reused)."
  value       = local.vpc_id
}

output "public_subnet_ids" {
  description = "List of all public subnet IDs created for this VPC."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "List of all private subnet IDs created for this VPC."
  value       = [for s in aws_subnet.private : s.id]
}

output "public_route_table_id" {
  description = "ID of the public route table (used by public subnets)."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table (used by private subnets)."
  value       = aws_route_table.private.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway attached to the VPC."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway associated with this VPC."
  value       = aws_nat_gateway.this.id
}

output "base_tags" {
  description = "Common static tags for traceability (without extra_tags)."
  value       = local.base_tags
}
