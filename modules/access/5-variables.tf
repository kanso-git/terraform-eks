##############################################
# 📥 INPUT VARIABLES — ACCESS CONTROL MODULE
##############################################

variable "aws_region" {
  type        = string
  description = "AWS region where the EKS cluster and IAM resources are deployed."
}

variable "environment" {
  type        = string
  description = "Environment label (e.g., dev, test, prod)."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name used for access mappings."
}

variable "namespaces" {
  type        = list(string)
  default     = []
  description = "List of Kubernetes namespaces for namespace-level RBAC roles."
}

variable "cluster_admin_users" {
  type        = list(string)
  default     = []
  description = "List of IAM usernames with cluster-wide admin access."
}

variable "cluster_viewer_users" {
  type        = list(string)
  default     = []
  description = "List of IAM usernames with cluster-wide viewer access."
}

variable "namespace_admin_users" {
  type        = any
  default     = {}
  description = "Either a flat list or a map(namespace → list of usernames) for namespace-level admins."
}

variable "namespace_viewer_users" {
  type        = any
  default     = {}
  description = "Either a flat list or a map(namespace → list of usernames) for namespace-level viewers."
}

# ✅ FIXED — Always a list for Terraform static depends_on
variable "cluster_dependency" {
  type        = list(any)
  default     = []
  description = "Optional list of resources (e.g., aws_eks_cluster) to depend on."
}

variable "owner" {
  type        = string
  default     = "experts-lab.com"
  description = "Owner or responsible team for these IAM and EKS access resources."
}

variable "creation_date" {
  type        = string
  default     = ""
  description = "Optional creation date for tagging (format: YYYY-MM-DD)."
}

variable "extra_tags" {
  type        = map(string)
  default     = {}
  description = "Additional custom tags merged with base tags."
}

# Optional toggle for eks:DescribeCluster permission
variable "add_eks_describe_cluster_permission" {
  type        = bool
  default     = true
  description = "If true, grants eks:DescribeCluster permission to IAM users for kubeconfig."
}
