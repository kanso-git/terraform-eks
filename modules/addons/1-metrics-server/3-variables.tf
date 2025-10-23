###########################################
# ⚙️ Variables — Metrics Server
###########################################

variable "namespace" {
  description = "Namespace where the Metrics Server will be installed."
  type        = string
  default     = "kube-system"
}

variable "chart_version" {
  description = "Helm chart version of the Metrics Server."
  type        = string
  default     = "3.12.1"
}
