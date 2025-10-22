#######################################################################
# 🔐 IAM MODULE — Input Variables
# ---------------------------------------------------------------------
# Defines configurable inputs for the IAM role module.
#######################################################################

variable "cluster_role_name" {
  description = "Name of the IAM role used by the EKS control plane."
  type        = string
  default     = "EKSClusterRole"
}

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)."
  type        = string
}

variable "owner" {
  description = "Owner or team responsible for the resources."
  type        = string
  default     = "experts-lab.com"
}

variable "creation_date" {
  description = "Creation date for tagging (YYYY-MM-DD). Leave empty to auto-generate."
  type        = string
  default     = ""
}

variable "extra_tags" {
  description = "Additional tags merged with the base ones."
  type        = map(string)
  default     = {}
}

variable "attach_policies" {
  description = "List of IAM policy ARNs to attach to the EKS cluster role."
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  ]
}
