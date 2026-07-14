output "cosmosdb_endpoint" {
  value = azurerm_cosmosdb_account.cosmosdb.endpoint
}

output "cosmosdb_key" {
  value     = azurerm_cosmosdb_account.cosmosdb.primary_key
  sensitive = true
}