# locals {
#   json = {
#     run = jsondecode(file("${path.module}/../../params/run.jsonc"))
#   }
  
#   tags = {
#     ProdRef      = local.json.run.prodref
#     ManagedBy    = local.json.run.managedby
#     Environment  = local.json.run.envShort
#     Workload       = local.json.run.workload
#   }
# }

resource "azurerm_windows_virtual_machine" "vm" {
  count               = var.vm_count
  name                = format("${var.vm_name_prefix}", count.index + 1)
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
    network_interface_ids = [
    element(var.network_interface_ids, count.index)
  ]
  os_disk {
    name                 = format("${var.vm_name_prefix}-osdisk", count.index + 1)
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
  }

  source_image_id = var.source_image_id
  license_type    = var.license_type

  identity {
    type = var.identity_type
  }
  tags = var.tags

  lifecycle {
    ignore_changes = [
      vm_agent_platform_updates_enabled
    ]
  }
}

output "vm_id" {
  value = azurerm_windows_virtual_machine.vm[*].id
}

output "vm_names" {
  value = azurerm_windows_virtual_machine.vm[*].name
}

output "identity_object_ids" {
  value = azurerm_windows_virtual_machine.vm[*].identity[0].principal_id
}

output "vm_resource_group_name" {
  value = azurerm_windows_virtual_machine.vm[*].resource_group_name
}