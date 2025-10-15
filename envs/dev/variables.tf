# =====================================================================
# 🌱 ENVIRONMENT VARIABLES — DEVELOPMENT
# ---------------------------------------------------------------------
# Defines the inputs required by the "dev" environment.
#
# These variables are passed to the VPC and EKS modules.
#   - VPC: Networking and subnet configuration
#   - EKS: Cluster name, version, IAM role, node groups
#
# Structure:
#   1. AWS and Environment Settings
#   2. Networking (VPC/Subnets)
#   3. Metadata (Tags, Owner, Creation Date)
#   4. EKS-Specific Variables (added below)
# =====================================================================


# ------------------------------------------------------------
# ☁️ AWS REGION
# ------------------------------------------------------------
# Defines the AWS region where this environment is deployed.
# This should match the backend S3 region and your provider region.
# ------------------------------------------------------------
variable "aws_region" {
  description = "AWS region for the dev environment."
  type        = string
  default     = "eu-central-2" # Zurich region
}


# ------------------------------------------------------------
# ☸️ CLUSTER NAME
# ------------------------------------------------------------
# Unique name for the EKS cluster.
# Used in tagging and Kubernetes context naming.
# ------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the EKS cluster to be deployed in this environment."
  type        = string
}


# ------------------------------------------------------------
# 🌐 VPC CIDR BLOCK
# ------------------------------------------------------------
# CIDR block for the main VPC in this environment.
# ------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR range for the development VPC (e.g., 10.0.0.0/16)."
  type        = string
}


# ------------------------------------------------------------
# 🌍 AVAILABILITY ZONES
# ------------------------------------------------------------
# List of AZs within the target AWS region.
# Example: ["eu-central-2a", "eu-central-2b", "eu-central-2c"]
# ------------------------------------------------------------
variable "azs" {
  description = "List of availability zones in Zurich region (eu-central-2)."
  type        = list(string)
}


# ------------------------------------------------------------
# 🌐 PUBLIC SUBNET CIDRS
# ------------------------------------------------------------
# CIDR blocks for each public subnet, one per AZ.
# ------------------------------------------------------------
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
}


# ------------------------------------------------------------
# 🔒 PRIVATE SUBNET CIDRS
# ------------------------------------------------------------
# CIDR blocks for each private subnet, one per AZ.
# Used for internal workloads, EKS nodes, and databases.
# ------------------------------------------------------------
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ)."
  type        = list(string)
}


# ------------------------------------------------------------
# 🌱 ENVIRONMENT IDENTIFIER
# ------------------------------------------------------------
# Used to distinguish between environments (dev, test, prod).
# ------------------------------------------------------------
variable "environment" {
  description = "Environment identifier (dev, test, prod)."
  type        = string
}


# ------------------------------------------------------------
# 👤 RESOURCE OWNER
# ------------------------------------------------------------
# Indicates who is responsible for this environment’s resources.
# ------------------------------------------------------------
variable "owner" {
  description = "Resource owner or responsible team."
  type        = string
  default     = "experts-lab.com"
}


# ------------------------------------------------------------
# 🏷️ EXTRA CUSTOM TAGS
# ------------------------------------------------------------
# Used to add optional metadata to all AWS resources.
# Example:
#   extra_tags = {
#     Project    = "EKS-MultiEnv"
#     CostCenter = "CC-DEV-001"
#   }
# ------------------------------------------------------------
variable "extra_tags" {
  description = "Additional tags to apply to all resources in this environment."
  type        = map(string)
  default     = {}
}


# ------------------------------------------------------------
# 🕓 CREATION DATE
# ------------------------------------------------------------
# Useful for auditing, tagging, and lifecycle policies.
# ------------------------------------------------------------
variable "creation_date" {
  description = "Timestamp for resource creation tracking."
  type        = string
  default     = "2025-10-10"
}



# =====================================================================
# ☸️ EKS-SPECIFIC VARIABLES — DEVELOPMENT
# ---------------------------------------------------------------------
# Defines inputs required for EKS deployment:
#   - Cluster version
#   - Control plane IAM role
#   - Node group configuration
# =====================================================================


# ------------------------------------------------------------
# 🧩 CLUSTER VERSION
# ------------------------------------------------------------
# Defines the Kubernetes version for the EKS cluster.
# Keep aligned with the latest AWS-supported version.
# Default is inherited from `global/variables.tf`, but can
# be overridden per environment if needed.
# ------------------------------------------------------------
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.33"
}


# ------------------------------------------------------------
# 🔐 CLUSTER ROLE ARN
# ------------------------------------------------------------
# IAM role ARN assigned to the EKS control plane.
# This role allows EKS to manage AWS resources (EC2, ELB, etc.).
# Typically created via a dedicated IAM module.
# ------------------------------------------------------------
variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane."
  type        = string
  default     = "arn:aws:iam::344230058523:role/EKSClusterRole" # 🔧 Replace with actual ARN
}


# ------------------------------------------------------------
# 🧑‍💻 NODE GROUP CONFIGURATION
# ------------------------------------------------------------
# Defines worker node group behavior:
#   - desired_capacity: number of initial nodes
#   - min_size / max_size: autoscaling limits
#   - instance_types: EC2 instance types used by nodes
# ------------------------------------------------------------
variable "node_groups" {
  description = "Map of managed node group configurations for EKS."
  type = map(object({
    desired_capacity = number
    min_size         = number
    max_size         = number
    instance_types   = list(string)
  }))
  default = {
    general = {
      desired_capacity = 1
      min_size         = 0
      max_size         = 3
      instance_types   = ["c7i-flex.large"]
    }
  }
}
