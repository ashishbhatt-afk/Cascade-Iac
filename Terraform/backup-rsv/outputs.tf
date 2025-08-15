output "recovery_vault_name" {
  value = azurerm_recovery_services_vault.rsv.name
}

output "recovery_vault_id" {
  value = azurerm_recovery_services_vault.rsv.id
}

output "backup_policy_id" {
  value = azurerm_backup_policy_vm.rsvpp.id
}

output "resource-group-name" {
  value = azurerm_resource_group.rg-rsv.name
}