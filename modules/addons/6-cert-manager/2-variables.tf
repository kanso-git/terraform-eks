variable "namespace" {
  description = "Namespace where cert-manager will be deployed"
  type        = string
  default     = "cert-manager"
}

variable "release_name" {
  description = "Helm release name for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "repository" {
  description = "Helm repository for cert-manager"
  type        = string
  default     = "https://charts.jetstack.io"
}

variable "chart" {
  description = "Helm chart name"
  type        = string
  default     = "cert-manager"
}

variable "chart_version" {
  description = "Helm chart version for cert-manager"
  type        = string
  # Use a stable recent version; adjust as you like
  default = "v1.15.0"
}

