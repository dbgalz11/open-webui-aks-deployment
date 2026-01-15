terraform {
  backend "azurerm" {
    subscription_id      = "367c3873-5d48-4c62-aec6-e23d28d181e4"
    resource_group_name  = "your-resource-group-name-here"
    storage_account_name = "your-storage-account-name-here"
    container_name       = "your-container-name-here"
    key                  = "your-key-here"
  }
}
