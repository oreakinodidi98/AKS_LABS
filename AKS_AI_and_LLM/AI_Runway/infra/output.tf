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

# -----------------------------------------------------------------------------
# Key Vault Outputs
# -----------------------------------------------------------------------------
output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = module.keyvault.key_vault_id
}
# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------
output "lustre_mgs_address" {
    description = "The MGS address of the managed Lustre file system"
    value       = module.network.lustre_mgs_address
}
output "lustre_fs_id" {
    description = "The ID of the managed Lustre file system"
    value       = module.network.lustre_fs_id
}
output "lustre_name" {
    description = "The name of the managed Lustre file system"
    value       = module.network.lustre_name
}
output "lustre_sku_name" {
    description = "The SKU name of the managed Lustre file system"
    value       = module.network.lustre_sku_name
}
output "lustre_subnet_id" {
    description = "The ID of the subnet for the managed Lustre file system"
    value       = module.network.lustre_subnet_id
}
output "lustre_subnet_name" {
    description = "The name of the subnet for the managed Lustre file system"
    value       = module.network.lustre_subnet_name
}
output "lustre_subnet_address_prefix" {
    description = "The address prefix of the subnet for the managed Lustre file system"
    value       = module.network.lustre_subnet_address_prefix
}
output "vnet_id" {
    description = "The ID of the virtual network"
    value       = module.network.vnet_id
}
output "vnet_name" {
    description = "The name of the virtual network"
    value       = module.network.vnet_name
}
output "vnet_address_space" {
    description = "The address space of the virtual network"
    value       = module.network.vnet_address_space
}
output "GPU_subnet_id" {
    description = "The ID of the GPU subnet"
    value       = module.network.GPU_subnet_id
}
output "GPU_subnet_name" {
    description = "The name of the GPU subnet"
    value       = module.network.GPU_subnet_name
}
output "GPU_subnet_address_prefix" {
    description = "The address prefix of the GPU subnet"
    value       = module.network.GPU_subnet_address_prefix
}
output "CPU_subnet_id" {
    description = "The ID of the CPU subnet"
    value       = module.network.CPU_subnet_id
}
output "CPU_subnet_name" {
    description = "The name of the CPU subnet"
    value       = module.network.CPU_subnet_name
}
output "CPU_subnet_address_prefix" {
    description = "The address prefix of the CPU subnet"
    value       = module.network.CPU_subnet_address_prefix
}
