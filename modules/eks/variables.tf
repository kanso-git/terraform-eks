# =====================================================================
# ☸️ VARIABLES — EKS MODULE
# ---------------------------------------------------------------------
# This file defines all input variables used by the EKS module.
# It serves as the single point of configuration for EKS-related
# parameters such as:
#   - Cluster name and version
#   - Networking (VPC ID, subnet IDs)
#   - IAM roles and permissions
#   - Node group definitions (instance types, scaling, etc.)
#   - Tags for traceability and cost allocation
#
# All values are typically passed from environment-level files
# (e.g., envs/dev/main.tf + dev.tfvars) or derived from global modules.
#
# This module is designed to be reusable across environments:
#   - dev
#   - test
#   - prod
#
# ⚙️ Note:
#   - The AWS provider must already be initialized at the environment level.
#   - The VPC module should be deployed first to provide the required inputs:
#       * vpc_id
#       * private_subnet_ids
#       * public_subnet_ids (optional for ALBs)
# =====================================================================


# ------------------------------------------------------------
# ☸️ EKS CLUSTER NAME
# ------------------------------------------------------------
# The name assigned to the EKS cluster.
# Used across resources for tagging and identification.
# ------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the EKS cluster (e.g., eks-dev-cluster)."
  type        = string
}


# ------------------------------------------------------------
# 🧩 CLUSTER VERSION
# ------------------------------------------------------------
# Specifies the Kubernetes version to use for the EKS cluster.
# This can be set globally in `global/variables.tf` for consistency.
# ------------------------------------------------------------
variable "cluster_version" {
  description = "Kubernetes version to deploy (e.g., 1.33)."
  type        = string
  default     = "1.33"
}


# ------------------------------------------------------------
# 🧱 VPC ID
# ------------------------------------------------------------
# The ID of the VPC where the EKS cluster and node groups will run.
# Passed from the VPC module via module output.
# ------------------------------------------------------------
variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed."
  type        = string
}


# ------------------------------------------------------------
# 🌐 SUBNETS
# ------------------------------------------------------------
# The subnets used by the EKS cluster:
#   - private_subnet_ids: used for worker nodes and control plane
#   - public_subnet_ids: (optional) used for load balancers
# ------------------------------------------------------------
variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS nodes."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for load balancers (optional)."
  type        = list(string)
  default     = []
}


# ------------------------------------------------------------
# 🧠 CLUSTER ROLE ARN
# ------------------------------------------------------------
# The IAM role used by the EKS control plane to interact with
# AWS resources such as EC2, ELB, etc.
# Usually created by an IAM module or inline here.
# ------------------------------------------------------------
variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane."
  type        = string
}


# ------------------------------------------------------------
# 🧑‍💻 NODE GROUP CONFIGURATION
# ------------------------------------------------------------
# Defines worker node groups for the cluster.
# Each node group can have its own instance type, scaling, etc.
# ------------------------------------------------------------
variable "node_groups" {
  description = <<EOT
Configuration for one or more managed node groups.
Each entry in this map defines:
  - desired_capacity
  - min_size
  - max_size
  - instance_types
Example:
  node_groups = {
    general = {
      desired_capacity = 2
      min_size         = 1
      max_size         = 3
      instance_types   = ["t3.medium"]
    }
  }
EOT
  type = map(object({
    desired_capacity = number
    min_size         = number
    max_size         = number
    instance_types   = list(string)
  }))
}


# ------------------------------------------------------------
# 🔒 SECURITY GROUP ADDITIONAL RULES (OPTIONAL)
# ------------------------------------------------------------
# Allows adding custom inbound/outbound rules to the EKS cluster
# or worker node security groups if needed.
# ------------------------------------------------------------
variable "additional_sg_rules" {
  description = "Optional additional security group rules for the cluster."
  type = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}


# ------------------------------------------------------------
# 🏷️ TAGS
# ------------------------------------------------------------
# Tags applied to all EKS-related resources for tracking.
# Merge this with global or environment tags at the environment level.
# ------------------------------------------------------------
variable "tags" {
  description = "Common tags to apply to all EKS resources."
  type        = map(string)
  default     = {}
}
