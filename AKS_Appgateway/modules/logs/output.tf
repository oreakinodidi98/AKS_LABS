output "azurerm_log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.aks.name
}
output "azurerm_log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.aks.id
}

output "app_insights_instrumentation_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}

output "app_insights_connection_string" {
  value     = azurerm_application_insights.main.connection_string
  sensitive = true
}