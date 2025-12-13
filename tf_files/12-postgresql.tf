# ============================================================================
# Azure Database for PostgreSQL Flexible Server
# Purpose: External database for Open WebUI (replaces SQLite)
# ============================================================================

# ----------------------------------------------------------------------------
# Data Sources
# ----------------------------------------------------------------------------

data "azurerm_subnet" "subnet" {
  name                 = "snet-postgresql"
  virtual_network_name = "vnet-aks"
  resource_group_name  = "rg-network"
}

data "azurerm_private_dns_zone" "pvtdns_postgre" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = "rg-network"
}

# -----------------------------------------------------------------------------
# Generate Strong Password
# -----------------------------------------------------------------------------
resource "random_password" "postgres_password" {
  length  = 32
  special = false
  # Ensure password meets Azure requirements
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  
}

# -----------------------------------------------------------------------------
# PostgreSQL Flexible Server
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "openwebui_db" {
  name                = local.postgresql_server_name
  resource_group_name = azurerm_resource_group.open_webui_nprod.name
  location            = azurerm_resource_group.open_webui_nprod.location
  
  # Network Configuration - Private Endpoint
  delegated_subnet_id           = data.azurerm_subnet.subnet.id
  private_dns_zone_id           = data.azurerm_private_dns_zone.pvtdns_postgre.id
  public_network_access_enabled = false

  # Administrator Credentials
  administrator_login    = local.postgresql_admin_username
  administrator_password = random_password.postgres_password.result
  
  # Server Configuration
  version        = "18"  # Latest stable PostgreSQL version
  sku_name       = "B_Standard_B1ms"  # Burstable tier for cost optimization
  storage_mb     = 32768  # 32GB storage
  storage_tier   = "P4"   # Performance tier for storage
  
  # Backup Configuration
  backup_retention_days        = 7     # Keep backups for 7 days
  geo_redundant_backup_enabled = false # Disable for cost savings (nprod)
  
  # High Availability (Optional - adds ~100% cost)
  # Uncomment for production with 99.99% SLA
  # high_availability {
  #   mode                      = "ZoneRedundant"
  #   standby_availability_zone = "2"  # Different zone from primary
  # }
  
  # Maintenance Window (Choose when updates happen)
  maintenance_window {
    day_of_week  = 2  # Tuesday
    start_hour   = 1  # 1 AM UTC (9 AM HKT)
    start_minute = 0
  }
  
  # Zone (match your AKS nodes)
  zone = "1"  # Same zone as AKS nodes for lower latency
  
  # Tags
  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }
  
  # Lifecycle
  lifecycle {
    #prevent_destroy = false  # Set to true in production!
    ignore_changes = [
      zone,  # Don't recreate if zone assignment changes
    ]
  }
}

# -----------------------------------------------------------------------------
# PostgreSQL Database
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_database" "openwebui" {
  name      = local.postgresql_database_name
  server_id = azurerm_postgresql_flexible_server.openwebui_db.id
  
  # Character set and collation
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# -----------------------------------------------------------------------------
# PostgreSQL Configuration (Performance Tuning)
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.openwebui_db.id
  value     = "100"  # Max concurrent connections
}

resource "azurerm_postgresql_flexible_server_configuration" "shared_buffers" {
  name      = "shared_buffers"
  server_id = azurerm_postgresql_flexible_server.openwebui_db.id
  value     = "32768"  # 32MB - good for B1ms (2GB RAM)
}

resource "azurerm_postgresql_flexible_server_configuration" "work_mem" {
  name      = "work_mem"
  server_id = azurerm_postgresql_flexible_server.openwebui_db.id
  value     = "4096"  # 4MB per operation
}


# -----------------------------------------------------------------------------
# Store Password in Key Vault
# -----------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  value        = random_password.postgres_password.result
  key_vault_id = azurerm_key_vault.openwebui_keyvault.id
  
  depends_on = [
    #azurerm_role_assignment.current_user_kv_admin # not configured yet
  ]
}

# Store connection string (for convenience)
resource "azurerm_key_vault_secret" "postgres_connection_string" {
  name  = "postgres-connection-string"
  value = "postgresql://${local.postgresql_admin_username}:${random_password.postgres_password.result}@${azurerm_postgresql_flexible_server.openwebui_db.fqdn}:5432/${local.postgresql_database_name}?sslmode=require"
  key_vault_id = azurerm_key_vault.openwebui_keyvault.id
  
  depends_on = [
    #azurerm_role_assignment.current_user_kv_admin # not configured yet
  ]
}

# Store server FQDN
resource "azurerm_key_vault_secret" "postgres_fqdn" {
  name         = "postgres-server-fqdn"
  value        = azurerm_postgresql_flexible_server.openwebui_db.fqdn
  key_vault_id = azurerm_key_vault.openwebui_keyvault.id
  
  depends_on = [
    #azurerm_role_assignment.current_user_kv_admin # not configured yet
  ]
}


# -----------------------------------------------------------------------------
# PostgreSQL Outputs
# -----------------------------------------------------------------------------
output "postgresql_server_name" {
  description = "PostgreSQL server name"
  value       = azurerm_postgresql_flexible_server.openwebui_db.name
}

output "postgresql_server_fqdn" {
  description = "PostgreSQL server fully qualified domain name"
  value       = azurerm_postgresql_flexible_server.openwebui_db.fqdn
}

output "postgresql_database_name" {
  description = "PostgreSQL database name"
  value       = azurerm_postgresql_flexible_server_database.openwebui.name
}

output "postgresql_admin_username" {
  description = "PostgreSQL administrator username"
  value       = local.postgresql_admin_username
  sensitive   = false
}

output "postgresql_connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${local.postgresql_admin_username}:***@${azurerm_postgresql_flexible_server.openwebui_db.fqdn}:5432/${local.postgresql_database_name}?sslmode=require"
  sensitive   = false
}

output "postgresql_connection_command" {
  description = "Command to connect to PostgreSQL"
  value       = "psql 'host=${azurerm_postgresql_flexible_server.openwebui_db.fqdn} port=5432 dbname=${local.postgresql_database_name} user=${local.postgresql_admin_username} sslmode=require'"
  sensitive   = false
}
