locals {
  ca_valid_hours   = 24
  cert_valid_hours = 8
  
  vault_certificate_folder = "../1-deploy/base/certs"
  vault_service_name       = "vault-server-tls"
  vault_service_namespace  = "vault"
}

//////////////////////////////////
// Certificate Authority Resources
//////////////////////////////////

resource "tls_private_key" "CA" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "CA" {
  private_key_pem       = tls_private_key.CA.private_key_pem
  validity_period_hours = local.ca_valid_hours

  subject {
    common_name  = "vault.k8s"
    organization = "Self-Signed CA (VAULT)"
  }

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

//////////////////////////////////
// Vault Private Key
//////////////////////////////////

resource "tls_private_key" "VAULT" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

//////////////////////////////////
// Vault Certificate Request
//////////////////////////////////

resource "tls_cert_request" "VAULT" {
  private_key_pem = tls_private_key.VAULT.private_key_pem

  subject {
    common_name  = local.vault_service_name
    organization = "HashiCorp Terraform"
  }

  ip_addresses = [
    "127.0.0.1"
  ]

  dns_names = [
    "localhost",
    join(".",[local.vault_service_name,local.vault_service_namespace]),
    join(".",[local.vault_service_name,local.vault_service_namespace,"svc"]),
    join(".",[local.vault_service_name,local.vault_service_namespace,"svc.cluster"]),
    join(".",[local.vault_service_name,local.vault_service_namespace,"svc.cluster.local"]),
  ]
}

//////////////////////////////////
// Vault Signed Certificate
//////////////////////////////////

resource "tls_locally_signed_cert" "VAULT" {
  ca_private_key_pem = tls_private_key.CA.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.CA.cert_pem
  cert_request_pem   = tls_cert_request.VAULT.cert_request_pem

  validity_period_hours = local.cert_valid_hours

  allowed_uses = [
    #"nonRepudiation",
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

//////////////////////////////////
// Vault Certificate Files
//////////////////////////////////

resource "local_sensitive_file" "VAULT_CA_CERT_PEM" {
  count = length(local.vault_certificate_folder) > 0 ? 1 :0

  content  = tls_self_signed_cert.CA.cert_pem
  filename = join("/", [local.vault_certificate_folder, "ca.pem"])
}

resource "local_sensitive_file" "VAULT_KEY_PEM" {
  count = length(local.vault_certificate_folder) > 0 ? 1 :0

  content  = tls_private_key.VAULT.private_key_pem
  filename = join("/", [local.vault_certificate_folder, "key.pem"])
}

resource "local_sensitive_file" "VAULT_CERT_PEM" {
  count = length(local.vault_certificate_folder) > 0 ? 1 :0

  content  = tls_locally_signed_cert.VAULT.cert_pem
  filename = join("/", [local.vault_certificate_folder, "crt.pem"])
}
