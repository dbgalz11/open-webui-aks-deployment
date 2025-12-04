terraform {
  required_version = "= 1.14.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = local.subscription_id
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "your-aks-context"  # Update to your AKS context name
}

# Cloudflare Provider configuration
# Retrieve Cloudflare API token from Key Vault
data "azurerm_key_vault" "kv_cloudflare" {
  name                = "your-cloudflare-kv-name"
  resource_group_name = "your-kv-resource-group"
}

data "azurerm_key_vault_secret" "cf_api_token" {
  name         = "cloudflare-api-token"
  key_vault_id = data.azurerm_key_vault.kv_cloudflare.id
}

provider "cloudflare" {
  api_token = data.azurerm_key_vault_secret.cf_api_token.value
}

# Configure the Azure Active Directory Provider
provider "azuread" {
  tenant_id = "YOUR_AZURE_TENANT_ID"
}
