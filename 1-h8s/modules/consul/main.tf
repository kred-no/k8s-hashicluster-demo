//////////////////////////////////
// Helm | Consul
//////////////////////////////////

resource "helm_release" "CONSUL" {
  name       = var.config.name
  namespace  = kubernetes_namespace_v1.MAIN.metadata.0.name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  version    = "v1.0.0-beta3"
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
