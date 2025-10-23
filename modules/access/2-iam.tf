##########################################
# 🔐 IAM Users (deduplicated)
# ----------------------------------------
# Creates one IAM user per unique username.
# Each user can be referenced later by ARN
# in EKS access entries and IAM policies.
##########################################

resource "aws_iam_user" "users" {
  for_each = local.all_users

  name          = each.key
  force_destroy = false

  tags = merge(local.common_tags, {
    Name      = each.key
    ManagedBy = "Terraform"
    Purpose   = "EKS-API-Auth"
  })
}

##########################################
# 📤 Outputs
##########################################

output "iam_user_arns" {
  description = "Map of IAM usernames to their ARNs (used for EKS access entries)."
  value       = { for username, user in aws_iam_user.users : username => user.arn }
}
