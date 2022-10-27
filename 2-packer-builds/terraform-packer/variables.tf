//////////////////////////////////
// Variables
//////////////////////////////////

variable "resource_group" {
  type = object({
    prefix   = optional(string, "Packer")
    location = optional(string, "northcentralus")
  })
  
  default = {}
}
