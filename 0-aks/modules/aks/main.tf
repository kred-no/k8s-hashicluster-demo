// Reads from bottom and up!

//////////////////////////////////
// AKS
//////////////////////////////////

resource "azurerm_kubernetes_cluster" "MAIN" {
  depends_on = [
    azurerm_role_assignment.NETWORK,
  ]

  name                = var.config.cluster_name
  dns_prefix          = var.config.prefix
  kubernetes_version  = var.config.cluster_version
  sku_tier            = var.config.cluster_sku
  location            = data.azurerm_resource_group.MAIN.location
  resource_group_name = data.azurerm_resource_group.MAIN.name
  tags                = var.config.tags

  identity {
    type = "UserAssigned"
    
    identity_ids = [
      azurerm_user_assigned_identity.MAIN.id,
    ]
  }

  node_resource_group = join("-", [data.azurerm_resource_group.MAIN.name, var.config.cluster_name])

  default_node_pool {
    name           = var.config.system_name
    node_count     = var.config.node_count
    max_pods       = var.config.node_max_pods
    vm_size        = var.config.node_size
    os_sku         = var.config.node_os
    vnet_subnet_id = azurerm_subnet.MAIN.id
  }
  
  network_profile {
    network_plugin    = var.config.network_plugin
    #network_policy    = var.config.network_policy
    load_balancer_sku = var.config.load_balancer_sku
    outbound_type     = "loadBalancer"
  }
}

//////////////////////////////////
// Permission Assignment
//////////////////////////////////
// User-defined role required when defining the subnet

resource "azurerm_role_assignment" "NETWORK" {
  depends_on = [azurerm_subnet_route_table_association.MAIN] // Needed?

  role_definition_name = "Network Contributor" // Builtin
  principal_id         = azurerm_user_assigned_identity.MAIN.principal_id
  scope                = data.azurerm_resource_group.MAIN.id
}

resource "azurerm_user_assigned_identity" "MAIN" {
  name                = var.config.cluster_name
  resource_group_name = data.azurerm_resource_group.MAIN.name
  location            = data.azurerm_resource_group.MAIN.location
}

//////////////////////////////////
// Network
//////////////////////////////////
// Route-table required when defining the subnet

resource "azurerm_subnet_route_table_association" "MAIN" {
  subnet_id      = azurerm_subnet.MAIN.id
  route_table_id = azurerm_route_table.MAIN.id
}

resource "azurerm_route_table" "MAIN" {
  name                = join("-", [azurerm_subnet.MAIN.name, var.config.system_name])
  location            = data.azurerm_resource_group.MAIN.location
  resource_group_name = data.azurerm_resource_group.MAIN.name
  tags                = var.config.tags
}

resource "azurerm_subnet_network_security_group_association" "MAIN" {
  subnet_id                 = azurerm_subnet.MAIN.id
  network_security_group_id = azurerm_network_security_group.MAIN.id
}

resource "azurerm_network_security_group" "MAIN" {
  name                = join("-", [azurerm_subnet.MAIN.name, "nsg"])
  location            = data.azurerm_resource_group.MAIN.location
  resource_group_name = data.azurerm_resource_group.MAIN.name
}

resource "azurerm_subnet" "MAIN" {
  name                 = var.config.subnet_name
  address_prefixes     = length(var.config.subnet_prefixes) > 0 ? var.config.subnet_prefixes : [cidrsubnet(element(data.azurerm_virtual_network.MAIN.address_space, 0), 3, 0)]
  resource_group_name  = data.azurerm_resource_group.MAIN.name
  virtual_network_name = data.azurerm_virtual_network.MAIN.name
}

//////////////////////////////////
// Parent Resources
//////////////////////////////////

data "azurerm_virtual_network" "MAIN" {
  name                = var.required.virtual_network.name
  resource_group_name = data.azurerm_resource_group.MAIN.name
}

data "azurerm_resource_group" "MAIN" {
  name = var.required.resource_group.name
}
