variable "required" {
  type = object({
    resource_group  = object({
      name = string
    })
    
    virtual_network = object({
      name = string
    })
  })
}

variable "config" {
  type = object({
    prefix            = optional(string, "hashinetes")
    cluster_name      = optional(string, "HashiN8S")
    cluster_sku       = optional(string, "Free")
    cluster_version   = optional(string, "1.24")
    system_name       = optional(string, "default")
    node_count        = optional(number, 1)
    node_size         = optional(string, "Standard_B2s")
    node_max_pods     = optional(number, 30)
    node_os           = optional(string, "CBLMariner")
    network_plugin    = optional(string, "kubenet")
    load_balancer_sku = optional(string, "basic")
    subnet_name       = optional(string, "AksSystem")
    subnet_prefixes   = optional(set(string), [])
    dns_name          = optional(string, "kred.h8s.io")
    tags              = optional(map(string), {})
  })

  default = {}
}