# Generates random secret key for Open WebUI session encryption

# Generate random 32-byte secret (equivalent to openssl rand -base64 32)
resource "random_bytes" "webui_secret_key" {
  length = 32  # 32 bytes
}

resource "azurerm_key_vault_secret" "webui_secret_key" {
  name         = local.webui_secret_key_name
  value        = random_bytes.webui_secret_key.base64  # Already base64 encoded
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

# Output (masked for security)
output "webui_secret_key_name" {
  description = "Key Vault secret name for WEBUI_SECRET_KEY"
  value       = azurerm_key_vault_secret.webui_secret_key.name
}

output "webui_secret_key_version" {
  description = "Secret version"
  value       = azurerm_key_vault_secret.webui_secret_key.version
}

# DO NOT output the actual secret value
output "webui_secret_key_value" {
   value     = random_bytes.webui_secret_key.base64
  sensitive = true
}