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
  config_context = "aks-nprod1"  # Updated to use the aks-nprod1 context
}

# Cloudflare Provider configuration
# Retrieve Cloudflare API token from Key Vault
data "azurerm_key_vault" "kv_pass_cf_nprod" {
  name                = "kv-pass-cf-nprod"
  resource_group_name = "rg-ea-kv-nprod"
}

data "azurerm_key_vault_secret" "cf_api_token" {
  name         = "cf008-admin-token-zero-trust-edit"
  key_vault_id = data.azurerm_key_vault.kv_pass_cf_nprod.id
}

provider "cloudflare" {
  api_token = data.azurerm_key_vault_secret.cf_api_token.value
}

# Configure the Azure Active Directory Provider
provider "azuread" {
  tenant_id = "c8794516-b0d6-41f8-ae73-7fb3bf77642c"
}
