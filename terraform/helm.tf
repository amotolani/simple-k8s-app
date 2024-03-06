resource "kubernetes_namespace" "monitoring" {
  depends_on = [module.eks]
  metadata {
    name = "monitoring"
  }
}

# Install metrics-server
resource "helm_release" "metrics-server" {
  depends_on = [module.eks, kubernetes_namespace.monitoring]
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.12.0"

  namespace = kubernetes_namespace.monitoring.metadata[0].name
}