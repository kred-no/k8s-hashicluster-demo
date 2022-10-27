locals {
  vmss = {
    sku_linux       = "Standard_B1ms"
    sku_windows     = "Standard_DS2_v2"
    admin_user      = "batman"
    disk_size_gb    = 80
    overprovision   = false
  }
  
  windows = true
  linux   = false
  public_access_enabled = true
}

//////////////////////////////////
// VMSS | Windows
//////////////////////////////////

resource "azurerm_windows_virtual_machine_scale_set" "MAIN" {
  count = local.windows ? 1 : 0

  name            = var.config.prefix
  instances       = var.config.instances
  priority        = var.config.priority
  eviction_policy = var.config.eviction_policy
  
  sku             = local.vmss.sku_windows
  admin_username  = local.vmss.admin_user
  admin_password  = "BruceW@yn3"
  overprovision   = local.vmss.overprovision

  source_image_id = data.azurerm_shared_image_version.WINDOWS.id

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.MAIN.id
      
      application_security_group_ids = [
        azurerm_application_security_group.MAIN.id,
      ]

      load_balancer_inbound_nat_rules_ids = flatten([
        local.public_access_enabled ? [
          one(azurerm_lb_nat_pool.RDP.*.id),
        ] : [],
      ])
    }
  }

  resource_group_name = azurerm_resource_group.MAIN.name
  location            = azurerm_resource_group.MAIN.location
}

//////////////////////////////////
// VMSS | Linux
//////////////////////////////////

resource "azurerm_linux_virtual_machine_scale_set" "MAIN" {
  count = local.linux ? 1 : 0

  name            = var.config.prefix
  instances       = var.config.instances
  priority        = var.config.priority
  eviction_policy = var.config.eviction_policy
  
  sku             = local.vmss.sku_linux
  admin_username  = local.vmss.admin_user
  overprovision   = local.vmss.overprovision
    
  source_image_id = data.azurerm_shared_image_version.LINUX.id

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = local.vmss.admin_user
    public_key = tls_private_key.MAIN.public_key_openssh
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.MAIN.id
      
      application_security_group_ids = [
        azurerm_application_security_group.MAIN.id,
      ]

      load_balancer_inbound_nat_rules_ids = flatten([
        local.public_access_enabled ? [
          one(azurerm_lb_nat_pool.SSH.*.id),
        ] : [],
      ])
    }
  }

  resource_group_name = azurerm_resource_group.MAIN.name
  location            = azurerm_resource_group.MAIN.location
}

//////////////////////////////////
// TLS Private key
//////////////////////////////////

resource "local_sensitive_file" "SSH_PRIVATE_KEY" {
  file_permission = "0600"
  content  = tls_private_key.MAIN.private_key_pem
  filename = "./id_rsa"
}

output "SSH_PRIVATE_KEY" {
  sensitive = true
  value = tls_private_key.MAIN.private_key_pem
}

resource "tls_private_key" "MAIN" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

//////////////////////////////////
// Image Version
//////////////////////////////////

data "azurerm_shared_image_version" "LINUX" {
  name                = "1.0.0"
  image_name          = "Debian"
  gallery_name        = "Packer"
  resource_group_name = "Packer-SIG-3563dd"
}

data "azurerm_shared_image_version" "WINDOWS" {
  name                = "1.0.1"
  image_name          = "WindowsServer"
  gallery_name        = "Packer"
  resource_group_name = "Packer-SIG-3563dd"
}

data "azurerm_platform_image" "MAIN" {
  location  = azurerm_resource_group.MAIN.location
  publisher = "debian"
  offer     = "debian-11"
  sku       = "11"
}

//////////////////////////////////
// LoadBalancer (Public SSH)
//////////////////////////////////

output "public_ip" {
  value = {
    fqdn = one(azurerm_public_ip.MAIN.*.fqdn)
    ip   = one(azurerm_public_ip.MAIN.*.ip_address)
  }
}

resource "azurerm_public_ip" "MAIN" {
  count               = local.public_access_enabled ? 1 : 0
  name                = "RemoteAccess"
  allocation_method   = "Static"
  domain_name_label   = join("",["packer" ,random_id.UID.hex])
  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
}

resource "azurerm_lb" "MAIN" {
  count = local.public_access_enabled ? 1 : 0
  name  = "public-lb"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = one(azurerm_public_ip.MAIN.*.id)
  }

  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
}

resource "azurerm_lb_nat_pool" "RDP" {
  count                          = local.public_access_enabled ? 1 : 0
  name                           = "rdp-natpool"
  protocol                       = "Tcp"
  frontend_port_start            = 5510
  frontend_port_end              = 5513
  backend_port                   = 3389
  frontend_ip_configuration_name = "PublicIPAddress"
  loadbalancer_id                = one(azurerm_lb.MAIN.*.id)
  resource_group_name            = azurerm_resource_group.MAIN.name
}

resource "azurerm_lb_nat_pool" "SSH" {
  count                          = local.public_access_enabled ? 1 : 0
  name                           = "ssh-natpool"
  protocol                       = "Tcp"
  frontend_port_start            = 5500
  frontend_port_end              = 5503
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  loadbalancer_id                = one(azurerm_lb.MAIN.*.id)
  resource_group_name            = azurerm_resource_group.MAIN.name
}

resource "azurerm_network_security_rule" "SSH" {
  count                       = local.public_access_enabled ? 1 : 0
  name                        = "AllowSSH"
  priority                    = 998
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  
  destination_application_security_group_ids  = [
    azurerm_application_security_group.MAIN.id,
  ]

  resource_group_name         = azurerm_resource_group.MAIN.name
  network_security_group_name = azurerm_network_security_group.MAIN.name
}

resource "azurerm_network_security_rule" "RDP" {
  count                       = local.public_access_enabled ? 1 : 0
  name                        = "AllowRDP"
  priority                    = 999
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  
  destination_application_security_group_ids  = [
    azurerm_application_security_group.MAIN.id,
  ]

  resource_group_name         = azurerm_resource_group.MAIN.name
  network_security_group_name = azurerm_network_security_group.MAIN.name
}

//////////////////////////////////
// Subnet
//////////////////////////////////

resource "azurerm_application_security_group" "MAIN" {
  name                = join("-", [var.config.prefix, "asg"])
  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
}

resource "azurerm_subnet_network_security_group_association" "MAIN" {
  subnet_id                 = azurerm_subnet.MAIN.id
  network_security_group_id = azurerm_network_security_group.MAIN.id
}

resource "azurerm_network_security_group" "MAIN" {
  name                = join("-", [azurerm_subnet.MAIN.name, "nsg"])
  location            = azurerm_resource_group.MAIN.location
  resource_group_name = azurerm_resource_group.MAIN.name
}

resource "azurerm_subnet" "MAIN" {
  name                 = "PackerVMs"
  address_prefixes     = ["192.168.99.0/28"]
  resource_group_name  = azurerm_resource_group.MAIN.name
  virtual_network_name = azurerm_virtual_network.MAIN.name
}

//////////////////////////////////
// Root Resources 
//////////////////////////////////

resource "azurerm_virtual_network" "MAIN" {
  name                = "PackerTest"
  address_space       = ["192.168.99.0/26"]
  resource_group_name = azurerm_resource_group.MAIN.name
  location            = azurerm_resource_group.MAIN.location
}

resource "azurerm_resource_group" "MAIN" {
  name     = join("-", [random_id.UID.keepers.prefix, "TEST", random_id.UID.hex])
  location = random_id.UID.keepers.location
}

resource "random_id" "UID" {
  byte_length = 2
  
  keepers = {
    prefix   = var.resource_group.prefix
    location = var.resource_group.location
  }
}
