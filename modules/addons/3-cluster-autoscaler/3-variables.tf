############################################################
# ⚙️ Variables — Cluster Autoscaler
############################################################

variable "cluster_name" {
  description = "EKS cluster name where the autoscaler will be deployed."
  type        = string
}

variable "aws_region" {
  description = "AWS region of the EKS cluster."
  type        = string
}

variable "chart_version" {
  description = "Version of the Cluster Autoscaler Helm chart."
  type        = string
  default     = "9.37.0" # Matches v1.30.x autoscaler for EKS
}
