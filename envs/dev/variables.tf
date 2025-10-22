# =====================================================================
# 🌐 DEV ENVIRONMENT — INPUT VARIABLES
# ---------------------------------------------------------------------
# Defines all input variables for the "dev" environment.
# These variables feed values into the VPC, IAM, and EKS modules.
#
# The file is intentionally explicit (no hidden defaults) to ensure
# isolation between environments (dev, test, prod).
# =====================================================================


# ------------------------------------------------------------
# ☁️ AWS REGION
# ------------------------------------------------------------
# Must match the backend S3 bucket region and the provider region.
# ------------------------------------------------------------
variable "aws_region" {
  description = "AWS region for the test environment."
  type        = string
  default     = "eu-central-2"
}


# ------------------------------------------------------------
# ☸️ CLUSTER NAME
# ------------------------------------------------------------
# Unique name for the EKS cluster.
# Used in tagging, IAM role names, and context.
# ------------------------------------------------------------
variable "cluster_name" {
  description = "EKS cluster name for the test environment."
  type        = string
}


# ------------------------------------------------------------
# 🌐 VPC CONFIGURATION
# ------------------------------------------------------------
# CIDR range and subnet configuration for the VPC.
# Public subnets are only needed for ALBs/NLBs (Ingress).
# ------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR range for the VPC."
  type        = string
}

variable "azs" {
  description = "List of Availability Zones used for subnets."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
}


# ------------------------------------------------------------
# 🌱 ENVIRONMENT METADATA
# ------------------------------------------------------------
variable "environment" {
  description = "Environment name identifier (e.g., dev, test, prod)."
  type        = string
}

variable "owner" {
  description = "Owner or responsible team for this environment."
  type        = string
  default     = "experts-lab.com"
}

variable "extra_tags" {
  description = "Additional custom tags applied to all resources."
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------
# 🕓 CREATION DATE
# ------------------------------------------------------------
# Dynamically set in locals (in main.tf).  Keep empty here.
# ------------------------------------------------------------
variable "creation_date" {
  description = "Static creation date (populated automatically at runtime)."
  type        = string
  default     = ""
}


# ------------------------------------------------------------
# ☸️ EKS SETTINGS
# ------------------------------------------------------------
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.33"
}


# ------------------------------------------------------------
# 🧩 NODE GROUP CONFIGURATION
# ------------------------------------------------------------
variable "node_groups" {
  description = "Map of node group definitions (scaling, instance types)."
  type = map(object({
    desired_capacity = number
    min_size         = number
    max_size         = number
    instance_types   = list(string)
  }))
}


# ------------------------------------------------------------
# 🔒 EKS ACCESS & API ENDPOINT
# ------------------------------------------------------------
# Controls whether the cluster API is reachable privately,
# publicly, or both. Used for security-hardening scenarios.
# ------------------------------------------------------------
variable "enable_endpoint_public_access" {
  description = "Allow public access to the EKS API endpoint."
  type        = bool
  default     = true
}

variable "enable_endpoint_private_access" {
  description = "Enable private access to the EKS API endpoint."
  type        = bool
  default     = false
}


# ------------------------------------------------------------
# 🧾 EKS ACCESS CONFIGURATION (Optional)
# ------------------------------------------------------------
# Allows you to define how the cluster is authenticated and
# whether the creator gets admin access automatically.
# ------------------------------------------------------------
variable "authentication_mode" {
  description = "EKS cluster authentication mode (optional, e.g., API)."
  type        = string
  default     = ""
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Grant cluster creator admin access automatically."
  type        = bool
  default     = false
}
