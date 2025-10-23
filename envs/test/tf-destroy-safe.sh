#!/usr/bin/env bash
set -euo pipefail

# ============================================
# 🧩 Safe Terraform Destroy (with stuck NS fix)
# ============================================

TFVARS="test.tfvars"

# Helper: remove finalizers from stuck namespaces
cleanup_stuck_namespaces() {
  echo ""
  echo "🔎 Checking for stuck namespaces (status=Terminating)..."
  local stuck_ns
  stuck_ns=$(kubectl get ns --no-headers 2>/dev/null | awk '$2=="Terminating"{print $1}')

  if [[ -z "$stuck_ns" ]]; then
    echo "✅ No stuck namespaces detected."
    return
  fi

  for ns in $stuck_ns; do
    echo "⚠️ Namespace '$ns' is stuck — attempting to remove finalizers..."
    kubectl get ns "$ns" -o json | jq 'del(.spec.finalizers)' | kubectl replace --raw "/api/v1/namespaces/$ns/finalize" -f - >/dev/null 2>&1 || true
    echo "✅ Finalizers removed for namespace: $ns"
  done
}

# 1️⃣ Pre-check: refresh kubeconfig
echo "🔁 Pre-check: refreshing kubeconfig for safety..."
aws eks update-kubeconfig --name "${TF_VAR_cluster_name:-eks-test-cluster}" \
  --region "${TF_VAR_aws_region:-eu-central-2}" >/dev/null 2>&1 || true
echo "✅ kubeconfig refreshed."

# ============================================
# 🧩 PHASE 1 — Destroy Kubernetes Add-ons
# ============================================
echo ""
echo "============================================="
echo "🧩 PHASE 1 — Destroy Kubernetes Add-ons"
echo "============================================="

terraform destroy -var-file="$TFVARS" \
  -target=module.cert_manager \
  -target=module.nginx_ingress \
  -target=module.aws_load_balancer_controller \
  -target=module.cluster_autoscaler \
  -target=module.metrics_server -auto-approve || {
    echo "⚠️ Phase 1 failed — attempting stuck namespace cleanup..."
    cleanup_stuck_namespaces
    echo "🔁 Retrying Phase 1 destroy..."
    terraform destroy -var-file="$TFVARS" \
      -target=module.cert_manager \
      -target=module.nginx_ingress \
      -target=module.aws_load_balancer_controller \
      -target=module.cluster_autoscaler \
      -target=module.metrics_server -auto-approve || true
  }

# ============================================
# 🧹 Extra cleanup before full destroy
# ============================================
cleanup_stuck_namespaces

# ============================================
# ☸️ PHASE 2 — Destroy Remaining Infrastructure
# ============================================
echo ""
echo "============================================="
echo "☸️ PHASE 2 — Destroy Remaining Infrastructure"
echo "============================================="

terraform destroy -var-file="$TFVARS" -auto-approve || {
  echo "⚠️ Final destroy failed — performing last stuck namespace cleanup..."
  cleanup_stuck_namespaces
  echo "🔁 Retrying final destroy..."
  terraform destroy -var-file="$TFVARS" -auto-approve
}

echo ""
echo "✅ All resources destroyed successfully!"
