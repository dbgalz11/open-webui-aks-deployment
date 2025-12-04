# Creates Cloudflare Tunnel and stores credentials in Azure Key Vault
# Generate random secret for tunnel

resource "cloudflare_zero_trust_tunnel_cloudflared" "openwebui_nprod_tunnel" {
  account_id    = local.cf_account_id
  name          = "openwebui-nprod-tunnel"
  config_src    = "cloudflare"
}

# Reads the token used to run the tunnel on the server.
data "cloudflare_zero_trust_tunnel_cloudflared_token" "openwebui_nprod_tunnel_token" {
  account_id   = local.cf_account_id
  tunnel_id   = cloudflare_zero_trust_tunnel_cloudflared.openwebui_nprod_tunnel.id
}

# Creates the CNAME record that routes your domain to the tunnel
resource "cloudflare_dns_record" "openwebui_dns_record" {
  zone_id = local.cf_zone_id
  name    = local.dns_record_name  # Will create open-webui.yourdomain.com
  content = "${cloudflare_zero_trust_tunnel_cloudflared.openwebui_nprod_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = "Open WebUI access via Cloudflare Tunnel"
}

# Configures tunnel with a published application for public access
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "openwebui_tunnel_config" {
  account_id = local.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.openwebui_nprod_tunnel.id
  config     = {
    ingress   = [
      {
        hostname = "${local.dns_record_name}.${local.cf_zone_name}"
        service  = "http://${local.dns_record_name}"
      },
      {
        service  = "http_status:404"
      }
    ]
  }
}

# Store Cloudflare Tunnel Token in Azure Key Vault
resource "azurerm_key_vault_secret" "cloudflare_tunnel_token" {
  name         = local.cf_tunnel_secret_name
  value        = data.cloudflare_zero_trust_tunnel_cloudflared_token.openwebui_nprod_tunnel_token.token
  key_vault_id = azurerm_key_vault.openwebui_keyvault.id

  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }

  depends_on = [
    azurerm_role_assignment.current_user_certificates_officer,
    data.cloudflare_zero_trust_tunnel_cloudflared_token.openwebui_nprod_tunnel_token
  ]
}

# Store Cloudflare Tunnel ID in Key Vault
resource "azurerm_key_vault_secret" "cloudflare_tunnel_id" {
  name         = local.cf_tunnel_id_secret_name
  value        = cloudflare_zero_trust_tunnel_cloudflared.openwebui_nprod_tunnel.id
  key_vault_id = azurerm_key_vault.openwebui_keyvault.id

  tags = {
    Owner       = local.TAG_OWNER
    Environment = local.TAG_ENVIRONMENT
    CreatedBy   = local.TAG_CREATED_BY
    CostType    = local.TAG_COSTTYPE
    Application = local.TAG_APPLICATION
  }

  depends_on = [
    azurerm_role_assignment.current_user_certificates_officer,
    cloudflare_zero_trust_tunnel_cloudflared.openwebui_nprod_tunnel
  ]
}



# Outputs
output "cloudflare_tunnel_id" {
  description = "Cloudflare Tunnel ID"
  value       = cloudflare_zero_trust_tunnel_cloudflared.openwebui_nprod_tunnel.id
}

output "cloudflare_tunnel_name" {
  description = "Cloudflare Tunnel Name"
  value       = cloudflare_zero_trust_tunnel_cloudflared.openwebui_nprod_tunnel.name
}

output "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel Token"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.openwebui_nprod_tunnel_token.token
}

output "cloudflare_tunnel_cname" {
  description = "Cloudflare Tunnel CNAME"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.openwebui_nprod_tunnel.id}.cfargotunnel.com"
}

output "cloudflare_dns_record" {
  description = "DNS record created for Open WebUI"
  value       = cloudflare_dns_record.openwebui_dns_record.name
}

output "cloudflare_tunnel_token_kv_secret_name" {
  description = "Key Vault secret name for Cloudflare Tunnel Token"
  value       = azurerm_key_vault_secret.cloudflare_tunnel_token.name
}