variable "config" {
  type = object({
    name             = optional(string, "vault")
    namespace        = optional(string, "vault")
    helm_values      = optional(set(string), [])
    ca_valid_hours   = optional(number, 24*365*50)
    cert_valid_hours = optional(number, 24*365*10)
  })
  
  default = {}
}