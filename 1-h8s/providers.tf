terraform {
  required_version = ">= 1.3.0"
  
  backend "local" {
    path = "../.statefiles/h8s-core.tfstate"
  }

  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    
    helm = {
      source = "hashicorp/helm"
    }
  }
}

//////////////////////////////////
// Kubernetes Provider
//////////////////////////////////
// !! NOT RECOMMENDED !!

// Fails without this (missing 'features').. Why?
provider "azurerm" {
  features {}
}

data "terraform_remote_state" "AKS" {
  backend = "local"
  
  config = {
    path = "../.statefiles/aks.tfstate"
  }
}

data "azurerm_kubernetes_cluster" "AKS" {
  name                = data.terraform_remote_state.AKS.outputs.provider_data_aks.cluster_name
  resource_group_name = data.terraform_remote_state.AKS.outputs.provider_data_aks.resource_group_name
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.AKS.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.AKS.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.AKS.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.AKS.kube_config.0.cluster_ca_certificate)
  config_path            = null
}

//////////////////////////////////
// Helm Provider
//////////////////////////////////

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.AKS.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.AKS.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.AKS.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.AKS.kube_config.0.cluster_ca_certificate)
    config_path            = null
  }
}