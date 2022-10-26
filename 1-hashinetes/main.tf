locals {
  certmgr_enabled = false
  vault_enabled   = false
  consul_enabled  = true
  nomad_enabled   = true
}

//////////////////////////////////
// Kubernetes | Nomad
//////////////////////////////////

module "NOMAD" {
  count      = local.nomad_enabled && local.consul_enabled ? 1 : 0
  source     = "./modules/nomad"
  depends_on = [module.CONSUL] // k get Uses ACL-token & gossip-key

  config = {
    name      = "nomad"
    namespace = "nomad"
  }
}

//////////////////////////////////
// Kubernetes | Consul
//////////////////////////////////

module "CONSUL" {
  count  = local.consul_enabled ? 1 : 0
  source = "./modules/consul"
  
  config = {
    name        = "consul"
    namespace   = "consul"
    helm_values = [file("./files/values.consul.yaml")]
  }
}

//////////////////////////////////
// Kubernetes | Vault
//////////////////////////////////
// Requires initialization & unseal!

module "VAULT" {
  count  = local.vault_enabled ? 1 :0
  source = "./modules/vault"
  
  config = {
    name        = "vault"
    namespace   = "vault"
    helm_values = [file("./files/values.vault.yaml")]
  }
}

//////////////////////////////////
// Kubernetes | Cert-Manager
//////////////////////////////////

module "CRTMGR" {
  count  = local.certmgr_enabled ? 1 :0
  source = "./modules/cert-manager"
  
  config = {
    name        = "cert-manager"
    namespace   = "cert-manager"
    helm_values = [file("./files/values.certmgr.yaml")]
  }
}