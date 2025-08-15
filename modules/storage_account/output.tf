output "storage_account_id" {
  description = "The ID of the Storage Account"
  value       = azurerm_storage_account.storage.id
}

output "storage_account_primary_endpoint" {
  description = "The primary endpoint for the Storage Account"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}