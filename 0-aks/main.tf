// Replace w/variables
locals {
  prefix            = "hashinetes"
  location          = "West Europe"
  network_name      = "HashiN8S"
  network_addresses = ["192.168.69.0/24"]

  tags = {
    Environment = "Demo"
    ConsulAPI   = "dc1"
    NomadAPI    = "dc1"
  }
}

//////////////////////////////////
// Kubernetes | Clusters
//////////////////////////////////

resource "local_file" "KUBECONFIG" {
  count = 1 // Only used for local testing. Can also download via az.

  content         = module.AKS.kube_config_raw
  filename        = "./kubeconfig"
  file_permission = "0600"
}

output "provider_data_aks" {
  value = module.AKS.provider_data
} // To be used by the kubernetes terraform provider (remote state)

module "AKS" {
  source = "./modules/aks"
  
  required = {
    resource_group  = azurerm_resource_group.MAIN
    virtual_network = azurerm_virtual_network.MAIN
  }

  config = {
    tags           = local.tags
    network_plugin = "azure"
    node_max_pods  = 30
    subnet_prefixes = [cidrsubnet(element(azurerm_virtual_network.MAIN.address_space, 0), 2, 0)]
  }
}

//////////////////////////////////
// Root Resources
//////////////////////////////////

output "provider_data_azurerm" {
  value = {
    resource_group_name  = azurerm_resource_group.MAIN.name
    virtual_network_name = azurerm_virtual_network.MAIN.name
  }
} // To be used by the workers terraform provider (remote state)

resource "azurerm_virtual_network" "MAIN" {
  name                = local.network_name
  address_space       = local.network_addresses
  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
  tags                = local.tags
}

resource "azurerm_resource_group" "MAIN" {
  name     = join("-", [random_id.ROOT.keepers.prefix, random_id.ROOT.hex])
  location = random_id.ROOT.keepers.location
  tags     = local.tags
}

resource "random_id" "ROOT" {
  keepers = {
    prefix   = local.prefix
    location = local.location
  }

  byte_length = 3
}

data "azurerm_subscription" "CURRENT" {}
