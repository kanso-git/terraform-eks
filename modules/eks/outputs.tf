##############################
# 📤 OUTPUTS — EKS MODULE
##############################

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "The endpoint URL of the EKS API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the EKS cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "node_group_names" {
  description = "List of all managed node group names."
  value       = [for ng in aws_eks_node_group.managed : ng.node_group_name]
}

output "node_group_arns" {
  description = "List of ARNs for all managed node groups."
  value       = [for ng in aws_eks_node_group.managed : ng.arn]
}

output "node_role_arn" {
  description = "IAM role ARN used by EKS worker nodes."
  value       = aws_iam_role.node_role.arn
}
