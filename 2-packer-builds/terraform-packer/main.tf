//////////////////////////////////
// Azure SIG | Windows
//////////////////////////////////

resource "azurerm_shared_image" "WINDOWS_DESKTOP" {
  name               = "WindowsDesktop"
  os_type            = "Windows"
  hyper_v_generation = "V2"
  gallery_name       = azurerm_shared_image_gallery.MAIN.name

  identifier {
    publisher = "Packer"
    offer     = "Windows"
    sku       = "11"
  }

  resource_group_name = azurerm_resource_group.GALLERY.name
  location            = azurerm_resource_group.GALLERY.location
}

resource "azurerm_shared_image" "WINDOWS_SERVER" {
  name         = "WindowsServer"
  os_type      = "Windows"
  hyper_v_generation = "V2"
  gallery_name       = azurerm_shared_image_gallery.MAIN.name

  identifier {
    publisher = "Packer"
    offer     = "Windows"
    sku       = "2022-datacenter"
  }

  resource_group_name = azurerm_resource_group.GALLERY.name
  location            = azurerm_resource_group.GALLERY.location
}

//////////////////////////////////
// Azure SIG | Linux
//////////////////////////////////

resource "azurerm_shared_image" "UBUNTU" {
  name               = "Ubuntu"
  os_type            = "Linux"
  hyper_v_generation = "V1"
  gallery_name       = azurerm_shared_image_gallery.MAIN.name

  identifier {
    publisher = "Packer"
    offer     = "Ubuntu"
    sku       = "22-04-lts"
  }

  resource_group_name = azurerm_resource_group.GALLERY.name
  location            = azurerm_resource_group.GALLERY.location
}

resource "azurerm_shared_image" "DEBIAN" {
  name               = "Debian"
  os_type            = "Linux"
  hyper_v_generation = "V1"
  gallery_name       = azurerm_shared_image_gallery.MAIN.name

  identifier {
    publisher = "Packer"
    offer     = "Debian"
    sku       = "11"
  }

  resource_group_name = azurerm_resource_group.GALLERY.name
  location            = azurerm_resource_group.GALLERY.location
}

//////////////////////////////////
// Azure Shared Image Gallery
//////////////////////////////////

resource "azurerm_shared_image_gallery" "MAIN" {
  name                = "Packer"
  description         = "Packer builds."
  resource_group_name = azurerm_resource_group.GALLERY.name
  location            = azurerm_resource_group.GALLERY.location
}

//////////////////////////////////
// Azure Resource Permissions
//////////////////////////////////

resource "azurerm_role_assignment" "GALLERY" {
  principal_id         = azuread_service_principal.MAIN.object_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.GALLERY.id
}

resource "azurerm_role_assignment" "IMAGE" {
  principal_id         = azuread_service_principal.MAIN.object_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.IMAGE.id
}

resource "azurerm_role_assignment" "BUILD" {
  principal_id         = azuread_service_principal.MAIN.object_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.BUILD.id
}

//////////////////////////////////
// Azure Resources
//////////////////////////////////

resource "azurerm_resource_group" "GALLERY" {
  depends_on = [azurerm_resource_group.IMAGE]
  name       = join("-", [random_id.UID.keepers.prefix, "SIG", random_id.UID.hex])
  location   = random_id.UID.keepers.location
}

resource "azurerm_resource_group" "IMAGE" {
  name     = join("-", [random_id.UID.keepers.prefix, "IMG", random_id.UID.hex])
  location = random_id.UID.keepers.location
}

resource "azurerm_resource_group" "BUILD" {
  name     = join("-", [random_id.UID.keepers.prefix, "TMP", random_id.UID.hex])
  location = random_id.UID.keepers.location
}

resource "random_id" "UID" {
  byte_length = 3
  
  keepers = {
    prefix   = var.resource_group.prefix
    location = var.resource_group.location
  }
}

//////////////////////////////////
// Azure AD credentials
//////////////////////////////////

resource "azuread_service_principal_password" "MAIN" {
  service_principal_id = azuread_service_principal.MAIN.object_id
}

resource "azuread_service_principal" "MAIN" {
  application_id               = azuread_application.MAIN.application_id
  app_role_assignment_required = true
  owners                       = [data.azuread_client_config.CURRENT.object_id]
}

resource "azuread_application" "MAIN" {
  display_name = "Packer"
  owners       = [data.azuread_client_config.CURRENT.object_id]
}

//////////////////////////////////
// Root Resources
//////////////////////////////////

data "azurerm_subscription" "CURRENT" {}
data "azuread_client_config" "CURRENT" {}
