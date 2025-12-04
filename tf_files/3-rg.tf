resource "azurerm_resource_group" "open_webui" {
  name     = local.resource_group_open_webui
  location = local.location


  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }
  
}