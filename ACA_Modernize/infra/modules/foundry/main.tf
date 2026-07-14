data "azurerm_client_config" "current" {}

resource "azurerm_cognitive_account" "foundry" {
  name                               = var.foundry_name
  location                           = var.location
  resource_group_name                = var.resourcegroup
  kind                               = "AIServices"
  sku_name                           = "S0"
  project_management_enabled         = true
  custom_subdomain_name              = var.custom_subdomain_name
  local_auth_enabled                 = true # either false or true
  public_network_access_enabled      = true
  outbound_network_access_restricted = false

  identity {
    type = "SystemAssigned"
  }

  tags = {
    SecurityControl = "Ignore"
  }
}

# Assign the Foundry User role on your Foundry resource to your user principal.
resource "azurerm_role_assignment" "foundry_user" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Foundry User"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_cognitive_account_project" "project" {
  name                 = var.foundry_project_name
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  location             = var.location
  description          = "Azure Foundry services project"
  display_name         = "Foundry Project"

  identity {
    type = "SystemAssigned"
  }
}

# Assign the Foundry User role on your Foundry resource to your project's managed identity.
resource "azurerm_role_assignment" "role_foundry_user" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Foundry User"
  principal_id         = azurerm_cognitive_account_project.project.identity.0.principal_id
}

# deploy model

resource "azurerm_cognitive_deployment" "gpt_54" {
  name                 = "gpt-5.4"
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  sku {
    name     = "GlobalStandard" #Options are "Standard", DataZoneStandard, GlobalBatch, GlobalStandard and ProvisionedManaged
    capacity = 1000
  }

  model {
    format  = "OpenAI"
    name    = "gpt-5.4"
    version = "2026-03-05"
  }
}

resource "azurerm_cognitive_deployment" "kimi_k26" {
  name                 = "Kimi-K2.6"
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  sku {
    name     = "GlobalStandard" #Options are "Standard", DataZoneStandard, GlobalBatch, GlobalStandard and ProvisionedManaged
    capacity = 100
  }

  model {
    format  = "MoonshotAI"
    name    = "Kimi-K2.6"
    version = "2026-04-20"
  }
}