output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = module.acr.name
}

output "acr_login_server" {
  description = "Login server for ACR"
  value       = module.acr.login_server
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.keyvault.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.keyvault.vault_uri
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of SQL Server"
  value       = module.database.server_fqdn
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.name
}

output "application_gateway_public_ip" {
  description = "Public IP of Application Gateway"
  value       = module.appgateway.public_ip_address
}

output "managed_identity_client_id" {
  description = "Client ID of the managed identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the managed identity"
  value       = azurerm_user_assigned_identity.aks.principal_id
}
