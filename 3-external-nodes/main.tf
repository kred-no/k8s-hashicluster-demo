//////////////////////////////////
// Nomad | Worker Nodes
//////////////////////////////////

module "WORKERS_LINUX" {
  source = "./modules/vmss-linux"
  
  required = {
    resource_group  = data.azurerm_resource_group.MAIN
    virtual_network = data.azurerm_virtual_network.MAIN
    subnet_prefixes = [cidrsubnet(element(data.azurerm_virtual_network.MAIN.address_space, 0), 2, 1)] 
  }

  // TODO: Create separate module for generating the rendered cloud-init
  config = {
    ci_userdata       = "files/ci-userdata.yaml"
    ci_scripts        = ["files/shell.install.sh"]
    ci_kubeconfig_raw = data.azurerm_kubernetes_cluster.AKS.kube_config_raw // TODO: Get file using az during provisioning
  }
}

//////////////////////////////////
// Base resources
//////////////////////////////////

data "azurerm_virtual_network" "MAIN" {
  name                = data.terraform_remote_state.AKS.outputs.provider_data_azurerm.virtual_network_name
  resource_group_name = data.azurerm_resource_group.MAIN.name
}

data "azurerm_resource_group" "MAIN" {
  name = data.terraform_remote_state.AKS.outputs.provider_data_azurerm.resource_group_name
}

data "azurerm_kubernetes_cluster" "AKS" {
  name                = data.terraform_remote_state.AKS.outputs.provider_data_aks.cluster_name
  resource_group_name = data.terraform_remote_state.AKS.outputs.provider_data_aks.resource_group_name
}

data "terraform_remote_state" "AKS" {
  backend = "local"
  
  config = {
    path = "../.statefiles/aks.tfstate"
  }
}
