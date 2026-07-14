resource "azurerm_service_plan" "app_service_plan_mcp_server" {
  name                = var.plan_name
  location            = var.location
  resource_group_name = var.resourcegroup
  os_type             = var.os_type
  sku_name            = var.sku_kind # B1 (basic) is cheap; use P0v3/P1v3 for production
}

resource "azurerm_linux_web_app" "mcp_server_open_web_search" {
  name                = var.appservice_name # must be globally unique
  location            = var.location
  resource_group_name = var.resourcegroup
  service_plan_id     = azurerm_service_plan.app_service_plan_mcp_server.id
  https_only          = false

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true # keep the container warm (requires Basic SKU or higher)

    application_stack {
      docker_image_name   = "aas-ee/open-web-search:v2.1.11" # check here for newer versions: https://github.com/Aas-ee/open-webSearch/pkgs/container/open-web-search
      docker_registry_url = "https://ghcr.io"
    }
  }

  app_settings = {
    # Tell App Service which port the container listens on
    WEBSITES_PORT = "3000"

    DEFAULT_SEARCH_ENGINE  = "startpage"            # bing, duckduckgo, exa, brave, baidu, csdn, juejin, startpage
    ALLOWED_SEARCH_ENGINES = "duckduckgo,startpage" # empty (all available) or comma-separated list of allowed engines
    ENABLE_CORS            = "true"
    CORS_ORIGIN            = "*"
    PORT                   = "3000" # 1-65535
  }
}