locals {
  tags = {
    environment = "demo"
    ManagedBy   = "Ore"
    workshop    = "AKS_automatic"
  }
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

resource "random_id" "random" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.resourcegroup.name
  }

  byte_length = 8
}
resource "azurerm_resource_group" "resourcegroup" {
  name     = var.resourcegroup
  location = var.location
  tags     = local.tags
}

module "aks_automatic" {
  source                = "./modules/aksautomatic"
  resourcegroup         = azurerm_resource_group.resourcegroup.name
  location              = var.location
  aks_cluster_name      = var.aks_cluster_name
  acr_name              = var.acr_name
  system_node_count     = var.system_node_count
  log_analytics_id      = module.monitoring.azurerm_log_analytics_workspace_id
  resourcegroup_id      = azurerm_resource_group.resourcegroup.id
  identity_prefix       = var.identity_prefix
  key_vault_id          = module.keyvault.key_vault_id
  ssh_public_key        = var.ssh_public_key
  ray_node_pool_vm_size = var.ray_node_pool_vm_size
  depends_on            = [module.monitoring]
}