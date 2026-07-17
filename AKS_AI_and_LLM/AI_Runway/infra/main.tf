locals {
  tags = {
    environment = "demo"
    ManagedBy   = "Ore"
    workshop    = "ai_runway"
  }
}

resource "random_integer" "example" {
  min = 10000
  max = 99999
}

resource "random_string" "example" {
  length  = 4
  upper   = false
  lower   = true
  numeric = false
  special = false
}

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.resourcegroup}${random_string.example.result}"
  location = var.location
  tags     = local.tags
}

data "azurerm_client_config" "current" {}

module "network" {
  source          = "./modules/network"
  location        = var.location
  resourcegroup   = azurerm_resource_group.resourcegroup.name
  vnet_name       = "${var.vnet_name}${random_string.example.result}"
  lustre_name     = "${var.lustre_name}${random_string.example.result}"
  lustre_sku_name = var.lustre_sku_name
}

module "aks" {
  source                = "./modules/aks"
  resourcegroup         = azurerm_resource_group.resourcegroup.name
  location              = var.location
  aks_cluster_name      = var.aks_cluster_name
  acr_name              = var.acr_name
  log_analytics_id      = module.monitoring.azurerm_log_analytics_workspace_id
  resourcegroup_id      = azurerm_resource_group.resourcegroup.id
  identity_prefix       = var.identity_prefix
  key_vault_id          = module.keyvault.key_vault_id
  ssh_public_key        = var.ssh_public_key
  aks_subnet_id         = module.network.CPU_subnet_id
  gpu_subnet_id         = module.network.GPU_subnet_id
  lustre_mgs_address    = module.network.lustre_mgs_address
  dns_prefix            = "${var.dns_prefix}${random_string.example.result}"
  aks_infrence_tempname = "${var.aks_infrence_tempname}${random_string.example.result}"
  depends_on            = [module.network]
}

module "monitoring" {
  source                      = "./modules/logs"
  env_name                    = var.env_name
  location                    = var.location
  resourcegroup               = azurerm_resource_group.resourcegroup.name
  log_analytics_workspace_sku = var.log_analytics_workspace_sku
  app_insights_name           = var.app_insights_name
  depends_on                  = [azurerm_resource_group.resourcegroup]
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