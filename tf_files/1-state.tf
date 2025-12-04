terraform {
  backend "azurerm" {
    subscription_id      = "367c3873-5d48-4c62-aec6-e23d28d181e4"
    resource_group_name  = "rg-tf-state"
    storage_account_name = "ststatefiles"
    container_name       = "ea-nprod"
    key                  = "ea-nprod-open-webui-oss.tfstate"
  }
}
