variable "vault_provider" {
  type = object({
    address         = optional(string, "https://127.0.0.1:8200")
    skip_tls_verify = optional(bool, true)
    token           = optional(string, "")
  })
}
