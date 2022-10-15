terraform {
  required_version = ">= 1.3.0"
  
  required_providers {
    tls = {
      source = "hashicorp/tls"
    }
  }
}

provider "tls" {}
