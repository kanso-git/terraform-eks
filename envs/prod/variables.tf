# =====================================================================
# 📦 Environment Variables — Production
# =====================================================================

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used for tagging and association."
  type        = string
}

variable "vpc_cidr" {
  description = "Base CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "List of availability zones for this environment."
  type        = list(string)
  default     = ["eu-central-2a", "eu-central-2b", "eu-central-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR ranges for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR ranges for private subnets."
  type        = list(string)
}
