variable "config" {
  type = object({
    name        = optional(string, "cert-mananger")
    namespace   = optional(string, "cert-mananger")
    helm_values = optional(set(string), [])
  })
  
  default = {}
}