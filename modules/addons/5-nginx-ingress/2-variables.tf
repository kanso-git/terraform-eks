variable "namespace" {
  description = "Namespace where the NGINX ingress controller will be deployed"
  type        = string
  default     = "ingress"
}

variable "chart_version" {
  description = "Helm chart version for the NGINX Ingress Controller"
  type        = string
  default     = "4.10.1"
}

variable "repository" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://kubernetes.github.io/ingress-nginx"
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "ingress-nginx"
}

variable "values_file" {
  description = "Optional path to a Helm values file"
  type        = string
  default     = null
}

