# =============================================================================
# OUTPUT VALUES
# These outputs provide important information for connecting your application
# =============================================================================

# -----------------------------------------------------------------------------
# Foundry Resource Outputs
# -----------------------------------------------------------------------------

output "foundry_endpoint" {
  value = module.foundry.foundry_endpoint
}

output "foundry_api_key" {
  value     = module.foundry.foundry_api_key
  sensitive = true
}

output "foundry_project_endpoint" {
  value = module.foundry.foundry_project_endpoint
}

output "llm_model_deployment_name_kimi" {
  value = module.foundry.llm_model_deployment_name_kimi
}

output "llm_model_deployment_name_chatgpt" {
  value = module.foundry.llm_model_deployment_name_chatgpt
}

# -----------------------------------------------------------------------------
# Cosmos DB Resource Outputs
# -----------------------------------------------------------------------------
output "cosmosdb_endpoint" {
  value = module.cosmosDB.cosmosdb_endpoint
}

output "cosmosdb_key" {
  value     = module.cosmosDB.cosmosdb_key
  sensitive = true
}
# -----------------------------------------------------------------------------
# App service Resource Outputs
# -----------------------------------------------------------------------------
output "app_service_mcp_server_open_web_search_fqdn" {
  value = module.appservice.app_service_mcp_server_open_web_search_fqdn
}
# -----------------------------------------------------------------------------
# ACA Resource Outputs
# -----------------------------------------------------------------------------
output "aca_mcp_server_open_web_search_fqdn" {
  value = module.aca.aca_mcp_server_open_web_search_fqdn
}
output "sessionpool_management_endpoint_shell" {
  value = module.aca.sessionpool_management_endpoint_shell
}

output "sessionpool_mcp_endpoint_shell" {
  value = module.aca.sessionpool_mcp_endpoint_shell
}

output "sessionpool_management_endpoint_python" {
  value = module.aca.sessionpool_management_endpoint_python
}

output "sessionpool_mcp_endpoint_python" {
  value = module.aca.sessionpool_mcp_endpoint_python
}