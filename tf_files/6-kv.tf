# Current Azure client configuration
data "azurerm_client_config" "current" {}

# Key Vault for Open WebUI Secrets
resource "azurerm_key_vault" "openwebui_keyvault" {
  name                        = local.key_vault_name
  location                    = azurerm_resource_group.open_webui.location
  resource_group_name         = azurerm_resource_group.open_webui.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 90
  purge_protection_enabled    = false
  rbac_authorization_enabled  = true

  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }

  depends_on = [ azurerm_user_assigned_identity.uai_openwebui ]
}


# RBAC: Grant current user permissions to manage certificates
resource "azurerm_role_assignment" "current_user_certificates_officer" {
  scope                = azurerm_key_vault.openwebui_keyvault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}


# RBAC: Grant UAI permissions to manage secrets
resource "azurerm_role_assignment" "uai_secrets_officer" {
  scope                = azurerm_key_vault.openwebui_keyvault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_user_assigned_identity.uai_openwebui.principal_id
}
