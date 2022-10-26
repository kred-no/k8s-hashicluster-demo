variable "config" {
  type = object({
    name        = optional(string, "consul")
    namespace   = optional(string, "consul")
    helm_values = optional(set(string), [])
  })
  
  default = {}
}