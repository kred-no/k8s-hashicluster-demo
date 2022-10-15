terraform {
  required_version = ">= 1.3.0"
  
  required_providers {
    vault = {
      source = "hashicorp/vault"
    }
  }
}

// https://registry.terraform.io/providers/hashicorp/vault/latest/docs
provider "vault" {
  skip_tls_verify = var.vault_provider.skip_tls_verify
  address         = var.vault_provider.address
  token           = var.vault_provider.token
}
