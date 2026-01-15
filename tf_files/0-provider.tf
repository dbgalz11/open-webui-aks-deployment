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
  config_context = "your-target-aks-cluster"  # Updated to use the aks-nprod context
}

# Cloudflare Provider configuration
# Retrieve Cloudflare API token from Key Vault
data "azurerm_key_vault" "kv_pass_cf_nprod" {
  name                = "your-key-vault-name-here"
  resource_group_name = "your-resource-group-name-here"
}

data "azurerm_key_vault_secret" "cf_api_token" {
  name         = "your-token-secret-name-here"
  key_vault_id = data.azurerm_key_vault.kv_pass_cf_nprod.id
}

provider "cloudflare" {
  api_token = data.azurerm_key_vault_secret.cf_api_token.value
}

# Configure the Azure Active Directory Provider
provider "azuread" {
  tenant_id = "your-tenant-id-here"
}
