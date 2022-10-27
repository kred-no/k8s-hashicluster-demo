locals {
  vmss = {
    sku             = "Standard_F2"
    admin_user      = "batman"
    disk_size_gb    = 80
    
    image_publisher = "debian"
    image_offer     = "debian-11"
    image_sku       = "11"
    image_version   = "latest"
    overprovision   = false
    
  }
  
  public_ssh_enabled = true
}

//////////////////////////////////
// LoadBalancer (Public SSH)
//////////////////////////////////

resource "azurerm_public_ip" "MAIN" {
  count               = local.public_ssh_enabled ? 1 : 0
  name                = "ssh-pip"
  allocation_method   = "Static"
  domain_name_label   = "h8s"
  #ip_tags             = {}
  #zones               = []
  
  location            = data.azurerm_resource_group.MAIN.location
  resource_group_name = data.azurerm_resource_group.MAIN.name
}

resource "azurerm_lb" "MAIN" {
  count = local.public_ssh_enabled ? 1 : 0
  name  = "ssh-lb"

  frontend_ip_configuration {
    name                 = "SSHPublicIPAddress"
    public_ip_address_id = one(azurerm_public_ip.MAIN.*.id)
  }

  location            = data.azurerm_resource_group.MAIN.location
  resource_group_name = data.azurerm_resource_group.MAIN.name
}

resource "azurerm_lb_nat_pool" "SSH" {
  count                          = local.public_ssh_enabled ? 1 : 0
  name                           = "ssh-natpool"
  protocol                       = "Tcp"
  frontend_port_start            = 5500
  frontend_port_end              = 5509
  backend_port                   = 22
  frontend_ip_configuration_name = "SSHPublicIPAddress"
  loadbalancer_id                = one(azurerm_lb.MAIN.*.id)
  resource_group_name            = data.azurerm_resource_group.MAIN.name
}

resource "azurerm_network_security_rule" "SSH" {
  count                       = local.public_ssh_enabled ? 1 : 0
  name                        = "allow-ssh"
  priority                    = 999
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  
  destination_application_security_group_ids  = [
    azurerm_application_security_group.MAIN.id,
  ]

  resource_group_name         = data.azurerm_resource_group.MAIN.name
  network_security_group_name = azurerm_network_security_group.MAIN.name
}

//////////////////////////////////
// VMSS
//////////////////////////////////

resource "azurerm_linux_virtual_machine_scale_set" "MAIN" {

  name            = var.config.prefix
  instances       = var.config.instances
  priority        = var.config.priority
  eviction_policy = var.config.eviction_policy
  
  sku             = local.vmss.sku
  admin_username  = local.vmss.admin_user
  overprovision   = local.vmss.overprovision
  
  
  // Trigger replace if cloud-init changes
  custom_data = random_id.CI.keepers.data  
  
  lifecycle {
    replace_triggered_by = [random_id.CI.hex]
  }

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = local.vmss.admin_user
    public_key = tls_private_key.MAIN.public_key_openssh
  }

  source_image_reference {
    publisher = local.vmss.image_publisher
    offer     = local.vmss.image_offer
    sku       = local.vmss.image_sku
    version   = local.vmss.image_version
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = local.vmss.disk_size_gb
  }

  network_interface {
    name    = "nic"
    primary = true
    #network_security_group_id = ""

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.MAIN.id
      
      application_security_group_ids = [
        azurerm_application_security_group.MAIN.id,
      ]

      load_balancer_inbound_nat_rules_ids = flatten([
        local.public_ssh_enabled ? one(azurerm_lb_nat_pool.SSH.*.id) : "",
      ])
    }
  }

  resource_group_name = data.azurerm_resource_group.MAIN.name
  location            = data.azurerm_resource_group.MAIN.location
}

resource "azurerm_application_security_group" "MAIN" {
  name                = join("-", [var.config.prefix, "asg"])
  location            = data.azurerm_resource_group.MAIN.location
  resource_group_name = data.azurerm_resource_group.MAIN.name
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
// Cloud-Init Userdata
//////////////////////////////////

resource "random_id" "CI" {
  byte_length = 4
  
  keepers = {
    data = data.cloudinit_config.MAIN.rendered
  }
}

data "cloudinit_config" "MAIN" {
  gzip          = false
  base64_encode = true
  
  part {
    content_type = "text/cloud-config"
    content      = file(var.config.ci_userdata)
    filename     = join("-",["tfci", "userdata"])
  }

  dynamic "part" {
    for_each = var.config.ci_scripts
    
    content {
      content_type = "text/x-shellscript"
      content      = file(part.value)
      filename     = join("-",["tfci", basename(part.value)])
    }
  }

  dynamic "part" {
    for_each = [var.config.ci_kubeconfig_raw]
    
    content {
      content_type = "text/x-shellscript"
      content = <<-KUBECONFIG
        #!/usr/bin/env sh
        mkdir -p /root/.kube
        echo "${base64gzip(part.value)}"|base64 -di|zcat|tee /root/.kube/config && exit 0
        KUBECONFIG
      filename = "tfci-kubeconfig"
    }
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-BIRTH
      #!/usr/bin/env sh
      date | tee -a /opt/birthcertificate.info && exit 0
      BIRTH
    filename = "tfci-birthcertificate.sh"
  }
}

//////////////////////////////////
// Subnet
//////////////////////////////////

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
  address_prefixes     = var.required.subnet_prefixes
  virtual_network_name = data.azurerm_virtual_network.MAIN.name
  resource_group_name  = data.azurerm_resource_group.MAIN.name
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
