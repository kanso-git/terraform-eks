output "namespace" {
  description = "Namespace where cert-manager is installed"
  value       = var.namespace
}

output "release_name" {
  description = "Helm release name for cert-manager"
  value       = var.release_name
}
