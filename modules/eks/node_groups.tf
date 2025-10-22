
##############################
# 🔐 IAM ROLE FOR EKS NODES
##############################
# Shared node IAM role used by all managed node groups in this module.
# Policies:
#   • AmazonEKSWorkerNodePolicy
#   • AmazonEKS_CNI_Policy
#   • AmazonEC2ContainerRegistryReadOnly
##############################

resource "aws_iam_role" "node_role" {
  name = local.node_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "ec2.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, { Name = local.node_role_name })
}

resource "aws_iam_role_policy_attachment" "node_role_attachments" {
  for_each = toset(var.node_role_policy_arns)

  role       = aws_iam_role.node_role.name
  policy_arn = each.value
}


##############################
# 🧩 MANAGED NODE GROUPS
##############################
# One managed node group per entry in var.node_groups.
# Uses dedicated IAM role created in iam.tf (aws_iam_role.node_role).
resource "aws_eks_node_group" "managed" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node_role.arn

  # Place nodes in private subnets for security
  subnet_ids = var.private_subnet_ids

  # Scaling config from the map
  scaling_config {
    desired_size = each.value.desired_capacity
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  # Instance types (multi-type supported)
  instance_types = each.value.instance_types

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-${each.key}-ng"
  })

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.node_role_attachments
  ]

  # Allow external changes without Terraform plan difference, such as cluster-autoscaler updates to desired size
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
