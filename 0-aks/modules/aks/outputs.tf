//////////////////////////////////
// AKS System
//////////////////////////////////

#output "cluster_client_certificate" {
#  sensitive = true
#  value     = azurerm_kubernetes_cluster.MAIN.kube_config.0.client_certificate
#}

output "kube_config_raw" {
  sensitive = true
  value     = azurerm_kubernetes_cluster.MAIN.kube_config_raw
}

output "kube_config" {
  sensitive = true
  value     = azurerm_kubernetes_cluster.MAIN.kube_config
}

output "provider_data" {
  value = {
    cluster_name             = var.config.cluster_name
    resource_group_name      = data.azurerm_resource_group.MAIN.name
    node_resource_group_name = azurerm_kubernetes_cluster.MAIN.node_resource_group
    vmss_prefix              = join("-", ["aks", var.config.system_name])
  }
}

output "aks_subnet" {
  value = azurerm_subnet.MAIN
}

output "aks_managed_identity" {
  value = azurerm_user_assigned_identity.MAIN
}

output "aks_resource_id" {
  value = azurerm_kubernetes_cluster.MAIN.id
}