/* 
 # No need will use dynamic provisioning with managed-csi storage class
 # NOTE!!! Disk must be created in the same resource group as the AKS nodes

# Azure Disk for Ollama (50Gi)
resource "azurerm_managed_disk" "ollama_disk" {
  name                 = local.ollama_disk_name
  location             = azurerm_resource_group.open_webui_nprod.location
  resource_group_name  = azurerm_resource_group.open_webui_nprod.name
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

  depends_on = [ azurerm_resource_group.open_webui_nprod ]

}


# Azure Disk for Open WebUI (10Gi)
resource "azurerm_managed_disk" "openwebui_disk" {
  name                 = local.openwebui_disk_name
  location             = azurerm_resource_group.open_webui_nprod.location
  resource_group_name  = azurerm_resource_group.open_webui_nprod.name
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

  depends_on = [ azurerm_resource_group.open_webui_nprod ]

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


# ============================================
# Data Sources (Reference Existing Resources)
# ============================================

# Reference existing Private DNS Zone for Azure Files
data "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = "rg-network"  
}

# Reference AKS VNet
data "azurerm_virtual_network" "aks_vnet" {
  name                = "vnet-aks" 
  resource_group_name = "rg-network"  
}

# reference existing subnet
data "azurerm_subnet" "private_endpoints" {
   name                 = "snet-private-endpoints"
   virtual_network_name = data.azurerm_virtual_network.aks_vnet.name
   resource_group_name  = data.azurerm_virtual_network.aks_vnet.resource_group_name
}



#Storage Account
resource "azurerm_storage_account" "open_webui_storage" {
  name                     = "${local.storage_account_name}"
  resource_group_name      = azurerm_resource_group.open_webui_nprod.name
  location                 = azurerm_resource_group.open_webui_nprod.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Disable public access (only after private endpoint is working!)
  public_network_access_enabled = false

  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }

  depends_on = [ azurerm_resource_group.open_webui_nprod ]
}


# Fileshare
resource "azurerm_storage_share" "open_webui_fileshare" {
  depends_on = [azurerm_storage_account.open_webui_storage]
  name                 = local.container_name
  storage_account_id   = azurerm_storage_account.open_webui_storage.id
  quota                = 50
}

# ============================================
# Private Endpoint for Azure Files
# ============================================

resource "azurerm_private_endpoint" "storage_file" {
  name                = "pe-${local.storage_account_name}-file"
  location            = azurerm_resource_group.open_webui_nprod.location
  resource_group_name = azurerm_resource_group.open_webui_nprod.name
  subnet_id           = data.azurerm_subnet.private_endpoints.id 
  
  private_service_connection {
    name                           = "psc-${local.storage_account_name}-file"
    private_connection_resource_id = azurerm_storage_account.open_webui_storage.id
    subresource_names              = ["file"]  # CRITICAL: Must be "file" for Azure Files
    is_manual_connection           = false
  }
  
  # Link to existing Private DNS Zone
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.file.id]
  }

  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }
  
  depends_on = [
    azurerm_storage_account.open_webui_storage
  ]
}


# For Key Vault integration (optional but recommended)
resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "storage-account-key"
  value        = azurerm_storage_account.open_webui_storage.primary_access_key
  key_vault_id = azurerm_key_vault.openwebui_keyvault.id

  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }
}

resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "storage-account-name"
  value        = azurerm_storage_account.open_webui_storage.name
  key_vault_id = azurerm_key_vault.openwebui_keyvault.id

  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }
}

# Storage Account outputs
output "storage_account_name" {
  value       = azurerm_storage_account.open_webui_storage.name
  description = "Storage account name for Open WebUI"
}

output "storage_account_id" {
  value       = azurerm_storage_account.open_webui_storage.id
  description = "Storage account resource ID"
}

output "storage_account_primary_key" {
  value       = azurerm_storage_account.open_webui_storage.primary_access_key
  sensitive   = true
  description = "Storage account primary access key"
}

output "fileshare_name" {
  value       = azurerm_storage_share.open_webui_fileshare.name
  description = "File share name for Open WebUI data"
}

output "fileshare_url" {
  value       = azurerm_storage_share.open_webui_fileshare.url
  description = "File share URL"
}

output "private_endpoint_id" {
  value       = azurerm_private_endpoint.storage_file.id
  description = "Private endpoint resource ID"
}

output "private_endpoint_ip" {
  value       = azurerm_private_endpoint.storage_file.private_service_connection[0].private_ip_address
  description = "Private IP address of the storage account"
}

output "private_endpoint_fqdn" {
  value       = "${azurerm_storage_account.open_webui_storage.name}.file.core.windows.net"
  description = "FQDN of storage account (will resolve to private IP via DNS zone)"
}