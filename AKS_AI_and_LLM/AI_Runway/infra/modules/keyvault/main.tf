/*
 * Key Vault Module
 * This module creates an Azure Key Vault for storing secrets used by the application,
 * such as database credentials, connection strings, and other sensitive information.
 */

# Generate a random string for uniqueness
resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}
# Azure Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "${var.kv_name}-kv-${random_string.kv_suffix.result}"
  location                    = var.location
  resource_group_name         = var.resourcegroup
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization   = true
  sku_name                    = "standard"
  tags                        = var.tags
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "main" {
  name                = "${var.identity_prefix}${random_integer.suffix.result}"
  location            = var.location
  resource_group_name = var.resourcegroup
}

# Role Assignments for Managed Identity on Key Vault
resource "azurerm_role_assignment" "identity_kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

resource "azurerm_role_assignment" "identity_kv_certificate_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Certificate User"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# Role Assignment for current user as Key Vault Administrator
resource "azurerm_role_assignment" "user_kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.object_id
}