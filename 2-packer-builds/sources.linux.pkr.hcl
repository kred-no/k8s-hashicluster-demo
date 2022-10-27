# az vm image list --publisher Canonical --sku gen2 --output table --all
locals {
  debian-11 = {
    vm_size         = "Standard_B1ms"
    cloud_init      = "./files/cloud-init/userdata.yaml"
    image_publisher = "debian"
    image_offer     = "debian-11"
    image_sku       = "11"
    image_version   = "latest"
  }

  ubuntu-focal = {
    image_publisher = "Canonical"
    image_offer     = "0001-com-ubuntu-server-focal"
    image_sku       = "20_04-lts-gen2"
    image_version   = "latest"
  }
}

//////////////////////////////////
// Packer Builds
//////////////////////////////////

source "azure-arm" "debian-11" {

  # Azure Authentication
  subscription_id = var.azure_credentials.subscription_id
  tenant_id       = var.azure_credentials.tenant_id
  client_id       = var.azure_credentials.client_id
  client_secret   = var.azure_credentials.client_secret

  # Build image
  build_resource_group_name = var.tmp_resource_group_name

  custom_data = base64encode(file(local.debian-11.cloud_init))

  vm_size         = local.debian-11.vm_size
  os_type         = "Linux"
  os_disk_size_gb = 40

  # Store image
  managed_image_resource_group_name = var.img_resource_group_name
  managed_image_name                = join("-", ["debian-11", local.build_timestamp])

  # Copy to SIG
  shared_image_gallery_destination {
    subscription         = var.shared_image_gallery.subscription_id
    resource_group       = var.shared_image_gallery.resource_group_name
    gallery_name         = var.shared_image_gallery.gallery_name
    image_name           = "debian"
    image_version        = "1.0.0"
    replication_regions  = local.sig_locations
    storage_account_type = "Standard_LRS"
  }

  # Source image
  image_publisher = local.debian-11.image_publisher
  image_offer     = local.debian-11.image_offer
  image_sku       = local.debian-11.image_sku
  image_version   = local.debian-11.image_version
}
