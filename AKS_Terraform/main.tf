locals {
  tags = {
    environment = "demo"
    ManagedBy   = "Ore"
    workshop    = "vm_bastion"
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



module "keyvault" {
  source = "./modules/keyvault"

  resourcegroup   = azurerm_resource_group.resourcegroup.name
  location        = var.location
  kv_name         = var.kv_name
  tenant_id       = data.azurerm_client_config.current.tenant_id
  object_id       = data.azurerm_client_config.current.object_id
  tags            = local.tags
  identity_prefix = var.identity_prefix
}

# Monitoring must be created BEFORE AKS (AKS needs Log Analytics ID)
module "monitoring" {
  source                      = "./modules/logs"
  env_name                    = var.env_name
  location                    = var.location
  resourcegroup               = azurerm_resource_group.resourcegroup.name
  log_analytics_workspace_sku = var.log_analytics_workspace_sku
  app_insights_name           = var.app_insights_name
  depends_on                  = [azurerm_resource_group.resourcegroup]
}

module "aks" {
  source            = "./modules/aks"
  resourcegroup     = azurerm_resource_group.resourcegroup.name
  location          = var.location
  aks_cluster_name  = var.aks_cluster_name
  acr_name          = var.acr_name
  system_node_count = var.system_node_count
  log_analytics_id  = module.monitoring.azurerm_log_analytics_workspace_id
  resourcegroup_id  = azurerm_resource_group.resourcegroup.id
  identity_prefix   = var.identity_prefix
  key_vault_id      = module.keyvault.key_vault_id
  ssh_public_key    = var.ssh_public_key
  #aks_subnet_id     = module.vnet.aks_subnet_id
  depends_on = [module.monitoring]
}

# AKS Diagnostic Settings - Created AFTER AKS exists (breaks circular dependency)
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "aks-diagnostics"
  target_resource_id         = module.aks.aks_id
  log_analytics_workspace_id = module.monitoring.azurerm_log_analytics_workspace_id

  enabled_log { category = "kube-apiserver" }
  enabled_log { category = "kube-controller-manager" }
  enabled_log { category = "kube-scheduler" }
  enabled_log { category = "kube-audit" }
  enabled_log { category = "cluster-autoscaler" }

  metric { category = "AllMetrics" }

  depends_on = [module.aks]
}