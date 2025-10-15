############################################################
# 🌍 Global Variables — definitions
# ----------------------------------------------------------
# These variables apply to all environments (dev/test/prod)
# and are imported automatically via the provider or modules.
############################################################

variable "aws_region" {
  description = "AWS region for all environments"
  type        = string
  default     = "eu-central-2" # Zurich
}

variable "aws_profile" {
  description = "AWS CLI profile used by Terraform"
  type        = string
  default     = "terraform-mfa"
}

variable "cluster_version" {
  description = "EKS Kubernetes version to deploy"
  type        = string
  default     = "1.33" # ✅ latest EKS version
}
