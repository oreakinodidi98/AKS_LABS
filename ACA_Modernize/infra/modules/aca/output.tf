output "aca_mcp_server_open_web_search_fqdn" {
  value = azurerm_container_app.mcp_server_open_web_search.ingress.0.fqdn
}

output "sessionpool_management_endpoint_shell" {
  value = azapi_resource.aca_session_pool_shell.output.properties.poolManagementEndpoint
}

output "sessionpool_mcp_endpoint_shell" {
  value = azapi_resource.aca_session_pool_shell.output.properties.mcpServerSettings.mcpServerEndpoint
}

output "sessionpool_management_endpoint_python" {
  value = azapi_resource.aca_session_pool_python.output.properties.poolManagementEndpoint
}

output "sessionpool_mcp_endpoint_python" {
  value = azapi_resource.aca_session_pool_python.output.properties.mcpServerSettings.mcpServerEndpoint
}