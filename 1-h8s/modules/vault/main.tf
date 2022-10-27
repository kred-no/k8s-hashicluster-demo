//////////////////////////////////
// Helm | Vault
//////////////////////////////////
// Requires manual initialization / unseal

resource "helm_release" "VAULT" {
  name       = var.config.name
  namespace  = kubernetes_namespace_v1.MAIN.metadata.0.name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "v0.22.0"
  values     = var.config.helm_values
  skip_crds  = false
}

//////////////////////////////////
// Kubernetes | Volumes
//////////////////////////////////

resource "kubernetes_secret" "TLS" {
  metadata {
    name      = "usersecret"
    namespace = var.config.namespace
  }

  data = {
    "ca.crt"  = tls_self_signed_cert.CA.cert_pem
    "tls.crt" = tls_locally_signed_cert.MAIN.cert_pem
    "tls.key" = tls_private_key.MAIN.private_key_pem
  }

  type = "kubernetes.io/tls"
}

//////////////////////////////////
// Kubernetes | Namespace
//////////////////////////////////

resource "kubernetes_namespace_v1" "MAIN" {
  metadata {
    name = var.config.namespace
  }
}

//////////////////////////////////
// TLS | Outputs
//////////////////////////////////

output "tls_bundle" {
  sensitive = true
  
  value = {
    ca_crt  = tls_self_signed_cert.CA.cert_pem
    tls_crt = tls_locally_signed_cert.MAIN.cert_pem
    tls_key = tls_private_key.MAIN.private_key_pem
  }
}

//////////////////////////////////
// TLS | CA Signed Certificates
//////////////////////////////////

resource "tls_locally_signed_cert" "MAIN" {
  ca_private_key_pem    = tls_private_key.CA.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.CA.cert_pem
  cert_request_pem      = tls_cert_request.MAIN.cert_request_pem
  validity_period_hours = var.config.cert_valid_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

//////////////////////////////////
// TLS | Certificate Requests
//////////////////////////////////

resource "tls_cert_request" "MAIN" {
  private_key_pem = tls_private_key.MAIN.private_key_pem

  subject {
    common_name  = join(".", [var.config.name, var.config.namespace])
    organization = "HashiCorp Terraform"
  }

  ip_addresses = [
    "127.0.0.1"
  ]

  dns_names = [
    "localhost",
    join(".",[var.config.name, var.config.namespace]),
    join(".",[var.config.name, var.config.namespace,"svc"]),
    join(".",[var.config.name, var.config.namespace,"svc.cluster"]),
    join(".",[var.config.name, var.config.namespace,"svc.cluster.local"]),
  ]
}

//////////////////////////////////
// TLS | Private Key
//////////////////////////////////

resource "tls_private_key" "MAIN" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

//////////////////////////////////
// TLS | Certificate Authority
//////////////////////////////////

resource "tls_self_signed_cert" "CA" {
  private_key_pem       = tls_private_key.CA.private_key_pem
  validity_period_hours = var.config.ca_valid_hours

  subject {
    common_name  = "hashinetes.k8s"
    organization = "Self-Signed CA (hashinetes)"
  }

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "tls_private_key" "CA" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}
