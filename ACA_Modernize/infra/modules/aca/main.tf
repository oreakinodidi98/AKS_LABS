terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azapi = {
      source = "azure/azapi"
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_container_app_environment" "aca_environment" {
  name                           = var.environment_name
  location                       = var.location
  resource_group_name            = var.resourcegroup
  public_network_access          = "Enabled"

  identity {
    type = "SystemAssigned"
  }

  workload_profile {
    name                  = "gp1"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_container_app" "ai_container_modernise" {
  container_app_environment_id = azurerm_container_app_environment.aca_environment.id
  name                         = var.aca_name
  resource_group_name          = var.resourcegroup
  revision_mode                = "Single"
  workload_profile_name        = "gp1"

  ingress {
    allow_insecure_connections = true
    client_certificate_mode    = "ignore"
    external_enabled           = true
    target_port                = 11434
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas                     = 1
    max_replicas                     = 3
    polling_interval_in_seconds      = 30
    cooldown_period_in_seconds       = 300
    termination_grace_period_seconds = 30

    container {
      image  = "ollama/ollama:latest"
      name   = "ai-container-modernise"
      cpu    = 8
      memory = "56Gi"

      env {
        name  = "OLLAMA_HOST"
        value = "0.0.0.0" #	1-65535
      }
      env {
        name  = "PORT"
        value = "11434" #	1-65535
      }
    }
  }
}

resource "azapi_resource" "aca_session_pool_shell" {
  type                      = "Microsoft.App/sessionPools@2025-02-02-preview"
  parent_id                 = var.resourcegroup_id
  name                      = var.aca_session_pool_shell
  location                  = var.location
  schema_validation_enabled = false
  response_export_values    = ["properties.poolManagementEndpoint", "properties.mcpServerSettings.mcpServerEndpoint"]

   body = {
    properties = {
      containerType      = "Shell"
      poolManagementType = "Dynamic"

      dynamicPoolConfiguration = {
        lifecycleConfiguration = {
          lifecycleType           = "Timed"
          coolDownPeriodInSeconds = 300
        }
      }

      scaleConfiguration = {
        maxConcurrentSessions = 5
      }

      sessionNetworkConfiguration = {
        status = "EgressEnabled"
      }

      mcpServerSettings = {
        isMCPServerEnabled = true # Add the "mcpServerSettings" section to enable the MCP server
      }
    }
  }
}

# role assignment to allow ACA environment to use the session pool
# Azure Container Apps Session Executor
resource "azurerm_role_assignment" "aca_session_pool_shell_contributor" {
  scope                = azapi_resource.aca_session_pool_shell.id
  role_definition_name = "Azure ContainerApps Session Executor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azapi_resource" "aca_session_pool_python" {
  type                      = "Microsoft.App/sessionPools@2025-02-02-preview"
  parent_id                 = var.resourcegroup_id
  name                      = var.aca_session_pool_python
  location                  = var.location
  schema_validation_enabled = false
  response_export_values    = ["properties.poolManagementEndpoint", "properties.mcpServerSettings.mcpServerEndpoint"]

   body = {
    properties = {
      containerType      = "PythonLTS"
      poolManagementType = "Dynamic"

      dynamicPoolConfiguration = {
        lifecycleConfiguration = {
          lifecycleType           = "Timed"
          coolDownPeriodInSeconds = 300
        }
      }

      scaleConfiguration = {
        maxConcurrentSessions = 5
      }

      sessionNetworkConfiguration = {
        status = "EgressEnabled"
      }

      mcpServerSettings = {
        isMCPServerEnabled = true # Add the "mcpServerSettings" section to enable the MCP server
      }
    }
  }
}

resource "azurerm_role_assignment" "aca_session_pool_python_contributor" {
  scope                = azapi_resource.aca_session_pool_python.id
  role_definition_name = "Azure ContainerApps Session Executor"
  principal_id         = data.azurerm_client_config.current.object_id
}