###########################################
# 📤 Outputs — Metrics Server
###########################################

output "metrics_server_status" {
  description = "Status of the Metrics Server Helm release."
  value       = helm_release.metrics_server.status
}
