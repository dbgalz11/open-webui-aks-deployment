# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "uai_openwebui" {
  name                = local.user_assigned_identity_name
  resource_group_name = azurerm_resource_group.open_webui.name
  location            = azurerm_resource_group.open_webui.location

  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }
}

