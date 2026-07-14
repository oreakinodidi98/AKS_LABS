resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = var.cosmos_name
  location            = var.location
  resource_group_name = var.resourcegroup
  offer_type          = var.cosmos_offer_type
  kind                = var.cosmos_kind

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }

  tags = {
    SecurityControl = "Ignore"
  }
}