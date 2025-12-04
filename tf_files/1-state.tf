terraform {
  backend "azurerm" {
    subscription_id      = "YOUR_AZURE_SUBSCRIPTION_ID"
    resource_group_name  = "your-tf-state-rg"
    storage_account_name = "yourtfstatestorage"
    container_name       = "tfstate"
    key                  = "open-webui.tfstate"
  }
}
