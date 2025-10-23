############################################################
# ⚙️ Variables — EKS Pod Identity Addon
############################################################

variable "cluster_name" {
  description = "The name of the EKS cluster where the Pod Identity addon will be installed."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, test, prod)."
  type        = string
}

variable "addon_version" {
  description = "Version of the Pod Identity Agent addon to install."
  type        = string
  default     = "v1.3.8-eksbuild.2" # #aws eks describe-addon-versions --region us-east-2 --addon-name eks-pod-identity-agent | grep addonVersion
}
