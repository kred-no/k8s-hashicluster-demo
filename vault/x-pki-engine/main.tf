//////////////////////////////////
// Mount PKI Secret Engine
//////////////////////////////////
// https://learn.hashicorp.com/tutorials/vault/pki-engine#step-1-generate-root-ca

resource "vault_mount" "ROOT" {
  path = "pki-root"
  type = "pki"
  
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 3600 * 24 * 365 * 10
}

//////////////////////////////////
// PKI |  Policy
//////////////////////////////////

resource "vault_policy" "ROOT" {
  name = "pki-operator-policy"

  policy = <<-POLICY
  # Enable secrets engine
  path "sys/mounts/*" {
    capabilities = [ "create", "read", "update", "delete", "list" ]
  }

  # List enabled secrets engine
  path "sys/mounts" {
    capabilities = [ "read", "list" ]
  }

  # Work with pki secrets engine
  path "pki*" {
    capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
  }
  POLICY
}

//////////////////////////////////
// PKI | Root CA
//////////////////////////////////

resource "vault_pki_secret_backend_root_cert" "ROOT" {
  backend               = vault_mount.ROOT.path
  type                  = "internal"
  common_name           = "Self-Signed Root CA"
  ttl                   = 3600 * 24 * 3650 // 10y
  organization          = "Kreditorforeningen"
}

resource "vault_pki_secret_backend_config_urls" "ROOT" {
  backend = vault_mount.ROOT.path
  
  issuing_certificates = [
    join("", ["https://127.0.0.1:8200", "/v1/pki/ca"]),
    join("", [var.vault_provider.address, "/v1/pki/ca"]),
  ]
  
  crl_distribution_points = [
    join("", ["https://127.0.0.1:8200", "/v1/pki/crl"]),
    join("", [var.vault_provider.address, "/v1/pki/crl"]),
  ]
}

//////////////////////////////////
// Mount PKI Intermediate Secret Engine
//////////////////////////////////
// https://learn.hashicorp.com/tutorials/vault/pki-engine#step-2-generate-intermediate-ca

resource "vault_mount" "INTERMEDIATE" {
  depends_on = [vault_mount.ROOT]
  
  path = "pki-intermediate"
  type = "pki"
  
  default_lease_ttl_seconds = 3600 * 8
  max_lease_ttl_seconds     = 3600 * 24 * 365 * 5
}

//////////////////////////////////
// PKI | Intermediate Root CA
//////////////////////////////////

resource "vault_pki_secret_backend_intermediate_cert_request" "INTERMEDIATE" {
  backend     = vault_mount.INTERMEDIATE.path
  type        = "internal"
  common_name = "Self-Signed Intermediate CA"
}

// Sign using Root CA
resource "vault_pki_secret_backend_root_sign_intermediate" "INTERMEDIATE" {
  backend     = vault_mount.ROOT.path
  csr         = vault_pki_secret_backend_intermediate_cert_request.INTERMEDIATE.csr
  common_name = "Self-Signed Intermediate CA"
  format      = "pem_bundle"
  ttl         = 3600 * 24 * 365 * 5
}

// Assign the certificate to Intermediate backend
resource "vault_pki_secret_backend_intermediate_set_signed" "INTERMEDIATE" {
  backend     = vault_mount.INTERMEDIATE.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.INTERMEDIATE.certificate_bundle
}

//////////////////////////////////
// PKI | Create Roles
//////////////////////////////////
// https://learn.hashicorp.com/tutorials/vault/pki-engine#step-3-create-a-role

resource "vault_pki_secret_backend_role" "ROOT" {
  backend          = vault_mount.ROOT.path
  name             = "pki-root-role"
  allow_any_name   = true
}

resource "vault_pki_secret_backend_role" "EXAMPLE" {
  backend          = vault_mount.INTERMEDIATE.path
  name             = "pki-example-role"
  allowed_domains  = ["example.com"]
  allow_subdomains =  true
}

//////////////////////////////////
// PKI | Request certificates
//////////////////////////////////
// https://learn.hashicorp.com/tutorials/vault/pki-engine#step-4-request-certificates

resource "tls_private_key" "EXAMPLE" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "EXAMPLE" {
  private_key_pem = tls_private_key.EXAMPLE.private_key_pem

  subject {
    common_name  = "www.example.com"
    organization = "ACME Examples, Inc"
  }
}

resource "vault_pki_secret_backend_sign" "EXAMPLE" {
  backend     = vault_mount.INTERMEDIATE.path
  name        = vault_pki_secret_backend_role.EXAMPLE.name
  csr         = tls_cert_request.EXAMPLE.cert_request_pem
  common_name = "www.example.com"
}

output "example" {
  sensitive = true
  value = vault_pki_secret_backend_sign.EXAMPLE.ca_chain
}

// https://learn.hashicorp.com/tutorials/vault/pki-engine#step-5-revoke-certificates
// https://learn.hashicorp.com/tutorials/vault/pki-engine#step-6-remove-expired-certificates
// https://learn.hashicorp.com/tutorials/vault/pki-engine#step-7-rotate-root-ca
// https://learn.hashicorp.com/tutorials/vault/pki-engine#step-8-create-a-cross-signed-intermediate
