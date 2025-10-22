#######################################################################
# ☸️ EKS MODULE — Input Variables
# ---------------------------------------------------------------------
# Defines all configurable inputs for the EKS module.
# Removes dynamic defaults (e.g., function calls in defaults) and
# delegates dynamic computation to locals.tf.
#######################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster (e.g., eks-dev-cluster)."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.33"
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane (with EKSClusterPolicy and EKSServicePolicy)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for worker nodes."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnets for load balancers."
  type        = list(string)
  default     = []
}

variable "node_groups" {
  description = "Configuration for EKS managed node groups."
  type = map(object({
    desired_capacity = number
    min_size         = number
    max_size         = number
    instance_types   = list(string)
  }))
  default = {}
}

variable "node_role_name" {
  description = "Name for the IAM role used by worker nodes. Computed dynamically if left empty."
  type        = string
  default     = ""
}

variable "node_role_policy_arns" {
  description = "IAM policy ARNs to attach to node IAM role."
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

variable "enable_endpoint_public_access" {
  description = "Allow public API server endpoint access."
  type        = bool
  default     = true
}

variable "enable_endpoint_private_access" {
  description = "Allow private API server endpoint access."
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)."
  type        = string
}

variable "owner" {
  description = "Owner or responsible team for tagging."
  type        = string
  default     = "experts-lab.com"
}

variable "creation_date" {
  description = "Static creation date (YYYY-MM-DD). Leave empty to auto-generate dynamically."
  type        = string
  default     = ""
}

variable "extra_tags" {
  description = "Additional user-defined tags."
  type        = map(string)
  default     = {}
}

variable "authentication_mode" {
  description = "EKS authentication mode (CONFIG_MAP, API_AND_CONFIG_MAP, or API)."
  type        = string
  default     = null
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Bootstrap an access entry granting cluster admin permissions to the creator."
  type        = bool
  default     = null
}
