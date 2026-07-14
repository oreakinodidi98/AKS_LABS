output "foundry_endpoint" {
  value = azurerm_cognitive_account.foundry.endpoint
}

output "foundry_api_key" {
  value     = azurerm_cognitive_account.foundry.primary_access_key
  sensitive = true
}

output "foundry_project_endpoint" {
  value = azurerm_cognitive_account_project.project.endpoints["AI Foundry API"]
}

output "llm_model_deployment_name_kimi" {
  value = azurerm_cognitive_deployment.kimi_k26.name
}

output "llm_model_deployment_name_chatgpt" {
  value = azurerm_cognitive_deployment.gpt_54.name
}
