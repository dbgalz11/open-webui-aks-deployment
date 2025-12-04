/* 
 # No need will use dynamic provisioning with managed-csi storage class
 # NOTE!!! Disk must be created in the same resource group as the AKS nodes

# Azure Disk for Ollama (50Gi)
resource "azurerm_managed_disk" "ollama_disk" {
  name                 = local.ollama_disk_name
  location             = azurerm_resource_group.open_webui.location
  resource_group_name  = azurerm_resource_group.open_webui.name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = "50"

  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }

  depends_on = [ azurerm_resource_group.open_webui ]

}


# Azure Disk for Open WebUI (10Gi)
resource "azurerm_managed_disk" "openwebui_disk" {
  name                 = local.openwebui_disk_name
  location             = azurerm_resource_group.open_webui.location
  resource_group_name  = azurerm_resource_group.open_webui.name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = "10"

  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }

  depends_on = [ azurerm_resource_group.open_webui ]

}

# Outputs for use in Kubernetes PV creation

output "openwebui_disk_id" {
  description = "Azure Disk ID for Open WebUI PV"
  value       = azurerm_managed_disk.openwebui_disk.id
}

output "openwebui_disk_name" {
  description = "Azure Disk name for Open WebUI PV"
  value       = azurerm_managed_disk.openwebui_disk.name
}

output "openwebui_disk_uri" {
  description = "Full disk URI for Kubernetes PV spec"
  value       = azurerm_managed_disk.openwebui_disk.id
}

*/