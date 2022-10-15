//////////////////////////////////
// Enable kv mount/engine
//////////////////////////////////

resource "vault_mount" "KVV2" {
  path        = "kvv2"
  description = "KV Version 2 secret engine mount"
  type        = "kv"
  
  options     = {
    version = "2"
  }

}

//////////////////////////////////
// Create example secret(s)
//////////////////////////////////

resource "vault_kv_secret_v2" "DEMO" {
  mount = vault_mount.KVV2.path
  name  = "secret"
  cas   = 1
  
  delete_all_versions = true
  
  data_json = jsonencode({
    zip       = "zap",
    foo       = "bar",
    hey       = "ho",
  })
}


//////////////////////////////////
// Azure | Vault Resources
//////////////////////////////////

data "azuread_client_config" "CURRENT" {}
data "azurerm_subscription" "CURRENT" {}

resource "azuread_application" "AUTH_BACKEND" {
  display_name = "vault-auth-backend-demo"
  owners       = [data.azuread_client_config.CURRENT.object_id]
}

resource "azuread_service_principal" "AUTH_BACKEND" {
  application_id               = azuread_application.AUTH_BACKEND.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.CURRENT.object_id]
}

resource "azuread_service_principal_password" "AUTH_BACKEND" {
  service_principal_id = azuread_service_principal.AUTH_BACKEND.object_id
}

resource "azurerm_role_definition" "AUTH_BACKEND" {
  name        = "vault-auth-backend-demo"
  description = "Vault Backend Role"

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/*/read",
      "Microsoft.Compute/virtualMachineScaleSets/*/read",
    ]

    not_actions = []
  }
  
  scope = data.azurerm_subscription.CURRENT.id  
  
  assignable_scopes = [
    data.azurerm_subscription.CURRENT.id,
  ]
}

resource "azurerm_role_assignment" "AUTH_BACKEND" {
  scope              = data.azurerm_subscription.CURRENT.id
  role_definition_id = azurerm_role_definition.AUTH_BACKEND.id
  principal_id       = azuread_service_principal.AUTH_BACKEND.id
}

//////////////////////////////////
// Auth Backend | Azure
//////////////////////////////////

resource "vault_auth_backend" "AZURE" {
  type = "azure"
}

resource "vault_azure_auth_backend_config" "MAIN" {
  backend       = vault_auth_backend.AZURE.path
  tenant_id     = data.azurerm_subscription.CURRENT.tenant_id
  client_id     = azuread_service_principal.AUTH_BACKEND.id
  client_secret = azuread_service_principal_password.AUTH_BACKEND.value
  
  resource      = "https://vault.hashicorp.com"
}
