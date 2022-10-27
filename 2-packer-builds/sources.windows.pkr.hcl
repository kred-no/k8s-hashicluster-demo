
locals {
  w2k22 = {
    vm_size = "Standard_B2ms" # Standard_D2_v2

    image_publisher = "MicrosoftWindowsServer"
    image_offer     = "WindowsServer"
    image_sku       = "2022-datacenter-azure-edition-smalldisk"
    image_version   = "latest"
  }

  win11 = {
    vm_size = "Standard_B2ms" # Standard_D2_v2

    image_publisher = "MicrosoftWindowsDesktop"
    image_offer     = "office-365"
    image_sku       = "win11-22h2-avd-m365"
    image_version   = "latest"
  }
}

//////////////////////////////////
// Packer Builds
//////////////////////////////////

source "azure-arm" "win2k22" {

  # Azure Authentication
  subscription_id = var.azure_credentials.subscription_id
  tenant_id       = var.azure_credentials.tenant_id
  client_id       = var.azure_credentials.client_id
  client_secret   = var.azure_credentials.client_secret

  # Build image
  build_resource_group_name = var.tmp_resource_group_name

  # Store image
  managed_image_resource_group_name = var.img_resource_group_name
  managed_image_name                = join("-", ["w2k22", local.build_timestamp])

  # Copy to SIG
  shared_image_gallery_destination {
    subscription         = var.shared_image_gallery.subscription_id
    resource_group       = var.shared_image_gallery.resource_group_name
    gallery_name         = var.shared_image_gallery.gallery_name
    image_name           = "WindowsServer"
    image_version        = "1.0.1"
    replication_regions  = local.sig_locations
    storage_account_type = "Standard_LRS"
  }

  # Source image
  image_publisher = local.w2k22.image_publisher
  image_offer     = local.w2k22.image_offer
  image_sku       = local.w2k22.image_sku
  image_version   = local.w2k22.image_version

  vm_size         = local.w2k22.vm_size
  os_type         = "Windows"
  os_disk_size_gb = 64

  communicator   = "winrm"
  winrm_timeout  = "5m"
  winrm_insecure = true
  winrm_use_ssl  = true
  winrm_username = "packer"
}

source "azure-arm" "win11" {

  # Azure Authentication
  subscription_id = var.azure_credentials.subscription_id
  tenant_id       = var.azure_credentials.tenant_id
  client_id       = var.azure_credentials.client_id
  client_secret   = var.azure_credentials.client_secret

  # Build image
  build_resource_group_name = var.tmp_resource_group_name

  # Store image
  managed_image_resource_group_name = var.img_resource_group_name
  managed_image_name                = join("-", ["w2k22", local.build_timestamp])

  # Copy to SIG
  shared_image_gallery_destination {
    subscription         = var.shared_image_gallery.subscription_id
    resource_group       = var.shared_image_gallery.resource_group_name
    gallery_name         = var.shared_image_gallery.gallery_name
    image_name           = "windows-desktop"
    image_version        = "1.0.0"
    replication_regions  = local.sig_locations
    storage_account_type = "Standard_LRS"
  }

  # Source image
  image_publisher = local.win11.image_publisher
  image_offer     = local.win11.image_offer
  image_sku       = local.win11.image_sku
  image_version   = local.win11.image_version

  vm_size         = local.win11.vm_size
  os_type         = "Windows"
  os_disk_size_gb = 64

  communicator   = "winrm"
  winrm_timeout  = "5m"
  winrm_insecure = true
  winrm_use_ssl  = true
  winrm_username = "packer"
}
