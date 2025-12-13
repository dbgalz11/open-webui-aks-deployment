# Fetches existing Azure AD App Registration details and stores in Key Vault

# Get current Azure AD tenant info
data "azuread_client_config" "current" {}

# Fetch existing App Registration by display name
data "azuread_application" "openwebui_app" {
  display_name = local.app_registration_name
}

# Fetch Service Principal for the app
data "azuread_service_principal" "openwebui_sp" {
  client_id = data.azuread_application.openwebui_app.client_id
}

# Store Microsoft Client ID in Key Vault
resource "azurerm_key_vault_secret" "client_id" {
  name         = local.client_id_secret_name
  value        = data.azuread_application.openwebui_app.client_id
  key_vault_id = azurerm_key_vault.openwebui_keyvault.id

  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }

  depends_on = [
    azurerm_role_assignment.current_user_certificates_officer
  ]
}

/*

# Fetch client secret from another Key Vault
data "azurerm_key_vault" "src_secrets_kv" {
  name                = "kv-app-reg-secrets"
  resource_group_name = "rg-ea-kv-prod"
}

data "azurerm_key_vault_secret" "src_client_secret" {
  name         = "open-webui-qndev"  # Name in source vault
  key_vault_id = data.azurerm_key_vault.src_secrets_kv.id
}


# Store Microsoft Tenant ID in Key Vault
resource "azurerm_key_vault_secret" "client_secret" {
  name         = local.client_secret_name
  value        = data.azurerm_key_vault_secret.src_client_secret.value
  key_vault_id = azurerm_key_vault.openwebui_keyvault.id

  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }

  depends_on = [
    azurerm_role_assignment.current_user_certificates_officer
  ]
}
*/


# Outputs
output "client_id" {
  description = "Microsoft OAuth Client ID"
  value       = data.azuread_application.openwebui_app.client_id
}

output "tenant_id" {
  description = "Microsoft Tenant ID"
  value       = data.azuread_client_config.current.tenant_id
}

output "app_object_id" {
  description = "Application Object ID"
  value       = data.azuread_application.openwebui_app.object_id
}

output "service_principal_object_id" {
  description = "Service Principal Object ID"
  value       = data.azuread_service_principal.openwebui_sp.object_id # can be seen in Enterprise Applications
}