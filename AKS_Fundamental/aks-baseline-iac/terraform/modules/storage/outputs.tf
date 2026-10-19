output "id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}
