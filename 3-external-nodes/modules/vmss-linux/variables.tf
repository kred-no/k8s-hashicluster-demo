variable "required" {
  type = object({
    resource_group  = any
    virtual_network = any
    subnet_prefixes = set(string)
  })
}

variable "config" {
  type = object({
    prefix            = optional(string, "workerlnx")
    subnet_name       = optional(string, "NomadWorkersLnx")
    instances         = optional(number, 1)
    priority          = optional(string, "Spot")
    eviction_policy   = optional(string, "Delete")
    ci_userdata       = optional(string, "")
    ci_scripts        = optional(set(string), [])
    ci_kubeconfig_raw = optional(string, "")
  })
  
  default = {}
}