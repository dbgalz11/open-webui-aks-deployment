# Attaches User Assigned Identity to existing VMSS node pool

# Data source: Get existing VMSS (AKS node pool)
data "azurerm_virtual_machine_scale_set" "aks_nodepool" {
  name                = local.vmss_name  # e.g., "aks-lin15n-31159445-vmss"
  resource_group_name = local.resource_group_aks_node  # MC_* resource group
}

/*
# Get current VMSS identity configuration
locals {
  # Current identity IDs on VMSS (if any)
  current_identity_ids = try(
    data.azurerm_virtual_machine_scale_set.aks_nodepool.identity[0].identity_ids,
    []
  )
  
  # Add our UAI to the list
  updated_identity_ids = concat(
    local.current_identity_ids,
    [azurerm_user_assigned_identity.uai_openwebui_nprod.id]
  )
  
  # Remove duplicates
  final_identity_ids = distinct(local.updated_identity_ids)
}
*/


# Attach UAI to VMSS using null_resource with Azure CLI
resource "null_resource" "attach_uai_to_vmss" {
  provisioner "local-exec" {
    command = <<-EOT
      az vmss identity assign \
        --resource-group ${local.resource_group_aks_node} \
        --name ${local.vmss_name} \
        --identities ${azurerm_user_assigned_identity.uai_openwebui_nprod.id}
    EOT
  }

  depends_on = [
    azurerm_user_assigned_identity.uai_openwebui_nprod,
    data.azurerm_virtual_machine_scale_set.aks_nodepool
  ]
}


# Output
output "vmss_name" {
  description = "VMSS name where UAI is attached"
  value       = local.vmss_name
}

output "vmss_resource_group" {
  description = "VMSS resource group"
  value       = local.resource_group_aks_node
}

output "uai_attached_to_vmss" {
  description = "Confirmation that UAI is attached to VMSS"
  value       = "UAI ${azurerm_user_assigned_identity.uai_openwebui_nprod.name} attached to VMSS ${local.vmss_name}"
  depends_on  = [null_resource.attach_uai_to_vmss]
}

