locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Location    = var.location
    }
  )
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags
}

# Managed Identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${local.resource_prefix}-aks"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

# Network Module
module "network" {
  source = "./modules/network"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  vnet_name                  = "vnet-${local.resource_prefix}"
  vnet_address_space         = var.vnet_address_space
  aks_subnet_name            = "snet-${local.resource_prefix}-aks"
  aks_subnet_address_prefix  = var.aks_subnet_address_prefix
  appgw_subnet_name          = "snet-${local.resource_prefix}-appgw"
  appgw_subnet_address_prefix = var.appgw_subnet_address_prefix
  tags                       = local.common_tags
}

# Azure Container Registry
module "acr" {
  source = "./modules/acr"

  name                = "acr${replace(local.resource_prefix, "-", "")}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Premium"
  tags                = local.common_tags
}

# Grant AKS managed identity access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_user_assigned_identity.aks.principal_id
  role_definition_name             = "AcrPull"
  scope                            = module.acr.id
  skip_service_principal_aad_check = true
}

# Key Vault
module "keyvault" {
  source = "./modules/keyvault"

  name                = "kv-${replace(local.resource_prefix, "-", "")}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.common_tags
}

# Grant AKS managed identity access to Key Vault
resource "azurerm_role_assignment" "aks_keyvault_secrets_user" {
  principal_id                     = azurerm_user_assigned_identity.aks.principal_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = module.keyvault.id
  skip_service_principal_aad_check = true
}

# AKS Cluster
module "aks" {
  source = "./modules/aks"

  cluster_name                = "aks-${local.resource_prefix}"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  kubernetes_version          = var.kubernetes_version
  vnet_subnet_id              = module.network.aks_subnet_id
  system_node_count           = var.aks_system_node_count
  system_vm_size              = var.aks_system_vm_size
  user_node_count             = var.aks_user_node_count
  user_vm_size                = var.aks_user_vm_size
  managed_identity_id         = azurerm_user_assigned_identity.aks.id
  managed_identity_client_id  = azurerm_user_assigned_identity.aks.client_id
  enable_private_cluster      = var.enable_private_cluster
  tags                        = local.common_tags

  depends_on = [
    azurerm_role_assignment.aks_acr_pull,
    azurerm_role_assignment.aks_keyvault_secrets_user
  ]
}

# Storage Account
module "storage" {
  source = "./modules/storage"

  name                = "st${replace(local.resource_prefix, "-", "")}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

# Azure SQL Database
module "database" {
  source = "./modules/database"

  server_name         = "sql-${local.resource_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  admin_username      = var.sql_admin_username
  admin_password      = var.sql_admin_password
  database_name       = "sqldb-${local.resource_prefix}"
  tags                = local.common_tags
}

# Application Gateway
module "appgateway" {
  source = "./modules/appgateway"

  name                = "appgw-${local.resource_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = module.network.appgw_subnet_id
  tags                = local.common_tags
}

# Data source for current Azure config
data "azurerm_client_config" "current" {}
