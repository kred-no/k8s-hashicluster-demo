//////////////////////////////////
// Shared Local variables
//////////////////////////////////

locals {
  build_timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
  sig_locations   = ["northcentralus"]
}

//////////////////////////////////
// Variables
//////////////////////////////////

variable "azure_credentials" {
  type = object({
    client_id       = string
    client_secret   = string
    subscription_id = string
    tenant_id       = string
  })
}

variable "img_resource_group_name" {
  type    = string
  default = ""
}

variable "tmp_resource_group_name" {
  type    = string
  default = ""
}

variable "shared_image_gallery" {
  type = object({
    subscription_id     = string
    resource_group_name = string
    gallery_name        = string
  })
}
