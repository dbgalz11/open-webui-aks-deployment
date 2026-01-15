locals {

  subscription_id           = "YOUR_AZURE_SUBSCRIPTION_ID"
  location                  = "eastasia"

  # resource groups
  resource_group_aks        = "rg-aks"
  resource_group_storage    = "rg-storage"
  resource_group_open_webui = "rg-open-webui"

  # storage account for open-webui files
  storage_account_name     = "stopenwebui"
  container_name           = "openwebui-data"
 

  # azure disks for pvc
  ollama_disk_name         = "ollama-disk"
  openwebui_disk_name      = "openwebui-disk"

  # uai
  user_assigned_identity_name = "uai-openwebui"

  # kv
  key_vault_name            = "kv-openwebui"
  cf_tunnel_secret_name     = "cf-tunnel-token"
  cf_tunnel_id_secret_name  = "cf-tunnel-id"
  client_id_secret_name     = "openwebui-client-id"
  client_secret_name        = "openwebui-client-secret"
  app_tenant_id_secret_name = "tenant-id"

  # cloudflare
  cf_account_id            = "YOUR_CLOUDFLARE_ACCOUNT_ID"
  cf_zone_id               = "YOUR_CLOUDFLARE_ZONE_ID"
  dns_record_name          = "open-webui"
  cf_zone_name             = "yourdomain.com"

  # app registration for sso
  app_registration_name     = "open-webui-app"

  # k8s deployment
  webui_secret_key_name     = "webui-secret-key"


  # AKS Node Pool / VMSS
  resource_group_aks_node = "rg-aks-nodes"  # nodepool resource group
  vmss_name               = "aks-nodepool-vmss"  # Your VMSS name
 
  # PostgreSQL
  postgresql_server_name    = "psql-openwebui"
  postgresql_admin_username = "openwebuiadmin"
  postgresql_database_name  = "openwebuidb"


  # TAGS
  TAG_OWNER                               = "your-email@example.com"
  TAG_ENVIRONMENT                         = "Production"
  TAG_CREATED_BY                          = "your-email@example.com"
  TAG_COSTTYPE                            = "Operations"
  TAG_APPLICATION                         = "Open-WebUI"

}
