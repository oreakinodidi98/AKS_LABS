# =============================================================================
# OUTPUT VALUES
# These outputs provide important information for connecting your application
# =============================================================================

# -----------------------------------------------------------------------------
# AKS Cluster Outputs
# -----------------------------------------------------------------------------
output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.aks_name
}

output "aks_cluster_id" {
  description = "The ID of the AKS cluster"
  value       = module.aks.aks_id
}

output "acr_login_server" {
  description = "The login server URL for the Azure Container Registry"
  value       = module.aks.acr_login_server
}
output "client_certificate" {
  description = "The client certificate for AKS cluster authentication"
  value       = module.aks.client_certificate
  sensitive   = true
}
output "client_key" {
  description = "The client key for AKS cluster authentication"
  value       = module.aks.client_key
  sensitive   = true
}
output "cluster_ca_certificate" {
  description = "The cluster CA certificate for AKS cluster authentication"
  value       = module.aks.cluster_ca_certificate
  sensitive   = true
}
output "cluster_password" {
  description = "The cluster password for AKS cluster authentication"
  value       = module.aks.cluster_password
  sensitive   = true
}
output "cluster_username" {
  description = "The cluster username for AKS cluster authentication"
  value       = module.aks.cluster_username
  sensitive   = true
}
output "host" {
  description = "The host for AKS cluster"
  value       = module.aks.host
  sensitive   = true
}
output "system_node_pool_name" {
  description = "The name of the system node pool"
  value       = module.aks.system_node_pool_name
}

# -----------------------------------------------------------------------------
# Key Vault Outputs
# -----------------------------------------------------------------------------
output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = module.keyvault.key_vault_id
}

