//////////////////////////////////
// Helm | Consul
//////////////////////////////////

resource "helm_release" "CONSUL" {
  name       = var.config.name
  namespace  = kubernetes_namespace_v1.MAIN.metadata.0.name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.10.0"
  values     = var.config.helm_values
  skip_crds  = false
}

//////////////////////////////////
// Kubernetes | Namespace
//////////////////////////////////

resource "kubernetes_namespace_v1" "MAIN" {
  metadata {
    name = var.config.namespace
  }
}
