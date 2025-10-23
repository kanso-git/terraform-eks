############################################################
# 🚀 Cluster Autoscaler (Helm Chart)
# ----------------------------------------------------------
# Installs the official Cluster Autoscaler using Helm and
# configures it to use the IAM role linked via Pod Identity.
############################################################

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.chart_version


  values = [
    yamlencode({
      autoDiscovery = {
        clusterName = var.cluster_name
      }
      awsRegion = var.aws_region
      rbac = {
        serviceAccount = {
          create = true
          name   = "cluster-autoscaler"
        }
      }

    })
  ]

  depends_on = [aws_eks_pod_identity_association.cluster_autoscaler]
}
