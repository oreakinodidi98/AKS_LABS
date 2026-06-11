locals {
  tags = {
    environment = "demo"
    ManagedBy   = "Ore"
    workshop    = "app_gateway"
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
  source               = "./modules/aks"
  resourcegroup        = azurerm_resource_group.resourcegroup.name
  location             = var.location
  aks_cluster_name     = var.aks_cluster_name
  acr_name             = var.acr_name
  system_node_count    = var.system_node_count
  log_analytics_id     = module.monitoring.azurerm_log_analytics_workspace_id
  resourcegroup_id     = azurerm_resource_group.resourcegroup.id
  identity_prefix      = var.identity_prefix
  ssh_public_key       = var.ssh_public_key
  aks_subnet_id        = module.network.aks_subnet_id
  appgateway_subnet_id = module.network.app_gateway_subnet_id
  pip_name             = var.pip_name
  appgateway_name      = var.appgateway_name
  depends_on           = [module.monitoring, module.network]
}

# vnet and subnet
module "network" {
  source        = "./modules/vnet"
  location      = var.location
  resourcegroup = azurerm_resource_group.resourcegroup.name
  vnet_name     = "${var.resourcegroup}-vnet-spoke"
}

# vm
module "VM" {
  source        = "./modules/vm"
  location      = var.location
  resourcegroup = azurerm_resource_group.resourcegroup.name
  vm_name       = "${var.resourcegroup}-vm-linux-jumpbox"
  nic_name      = "${var.resourcegroup}-nic-vm-linux"
  vm_subnet_id  = module.network.vm_subnet_id
}