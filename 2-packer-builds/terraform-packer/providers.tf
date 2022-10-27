terraform {
  required_version = ">= 1.3.0"
  
  backend "local" {
    path = "./../../.statefiles/packer.tfstate"
  }

  required_providers {
    local = {
      source = "hashicorp/local"
    }
    
    random = {
      source = "hashicorp/random"
    }

    azurerm = {
      source = "hashicorp/azurerm"
    }
    
    azuread = {
      source = "hashicorp/azuread"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      // Built images are not managed by terraform;
      // this ensures they are deleted as well.
      prevent_deletion_if_contains_resources = false
    }
  }
}
