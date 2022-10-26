variable "config" {
  type = object({
    name           = optional(string, "nomad")
    namespace      = optional(string, "nomad")
    image_name     = optional(string, "kdsda/nomad")
    image_version  = optional(string, "alpine-1.4.1")
    
    consul_version                = optional(string, "latest")
    consul_secrets_namespace      = optional(string, "consul")
    consul_encryption_secret_name = optional(string, "consul-gossip-encryption-key")
    consul_acl_token_secret_name  = optional(string, "consul-bootstrap-acl-token")
  })
  
  default = {}
}