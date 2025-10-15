# =====================================================================
# 🌱 ENVIRONMENT VARIABLES — DEVELOPMENT
# ---------------------------------------------------------------------
# Defines the inputs required by the "dev" environment.
# These variables are passed to the VPC (and later EKS) modules.
# 
# All variables here correspond 1:1 with the module interface.
# =====================================================================


variable "aws_region" {
  description = "AWS region for the dev environment"
  type        = string
  default     = "eu-central-2"
}

# ------------------------------------------------------------
# ☸️ Cluster Name
# ------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the EKS cluster to be deployed in this environment."
  type        = string
}

# ------------------------------------------------------------
# 🌐 VPC CIDR Block
# ------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR range for the development VPC (e.g., 10.0.0.0/16)."
  type        = string
}

# ------------------------------------------------------------
# 🌍 Availability Zones
# ------------------------------------------------------------
variable "azs" {
  description = "List of availability zones in Zurich region (eu-central-2)."
  type        = list(string)
}

# ------------------------------------------------------------
# 🌐 Public Subnet CIDRs
# ------------------------------------------------------------
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
}

# ------------------------------------------------------------
# 🔒 Private Subnet CIDRs
# ------------------------------------------------------------
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ)."
  type        = list(string)
}

# ------------------------------------------------------------
# 🌱 Environment
# ------------------------------------------------------------
variable "environment" {
  description = "Environment identifier (dev, test, prod)."
  type        = string
}

# ------------------------------------------------------------
# 👤 Owner
# ------------------------------------------------------------
variable "owner" {
  description = "Resource owner or responsible team."
  type        = string
  default     = "experts-lab.com"
}

# ------------------------------------------------------------
# 🏷️ Extra Custom Tags
# ------------------------------------------------------------
variable "extra_tags" {
  description = "Additional tags to apply to all resources in this environment."
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------
# 🕓 Creation Date
# ------------------------------------------------------------
variable "creation_date" {
  description = "Timestamp for resource creation tracking."
  type        = string
  default     = "2025-10-10"
}
