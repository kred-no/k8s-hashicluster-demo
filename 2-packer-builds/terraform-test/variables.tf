variable "resource_group" {
  type = object({
    prefix   = string
    location = string
  })
  default = {
    prefix   = "Packer"
    location = "northcentralus"
  }
}

variable "config" {
  type = object({
    prefix            = optional(string, "packer")
    instances         = optional(number, 1)
    priority          = optional(string, "Spot")
    eviction_policy   = optional(string, "Delete")
    ci_userdata       = optional(string, "")
    ci_scripts        = optional(set(string), [])
    ci_kubeconfig_raw = optional(string, "")
  })
  
  default = {}
}