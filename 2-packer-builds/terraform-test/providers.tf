terraform {
  required_version = ">= 1.3.0"
  
  backend "local" {
    path = "../.statefiles/packer-test.tfstate"
  }

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

//////////////////////////////////
// Azure providers
//////////////////////////////////

provider "azurerm" {
  features {
    resource_group {
      // Will delete any non-terraform resources
      prevent_deletion_if_contains_resources = false
    }
  }
}
