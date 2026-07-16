# Generate random suffix for unique resource names
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "${var.env_name}-loga${random_integer.suffix.result}"
  location            = var.location
  resource_group_name = var.resourcegroup
  sku                 = var.log_analytics_workspace_sku

  lifecycle {
    ignore_changes = [
      name,
    ]
  }
}
resource "azurerm_monitor_workspace" "aks_monitor_workspace" {
  name                = "${var.env_name}-monitor"
  resource_group_name = var.resourcegroup
  location            = var.location
}
resource "azurerm_log_analytics_solution" "aks-containerinsights" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.aks.location
  resource_group_name   = var.resourcegroup
  workspace_resource_id = azurerm_log_analytics_workspace.aks.id
  workspace_name        = azurerm_log_analytics_workspace.aks.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}
# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${var.app_insights_name}${random_integer.suffix.result}"
  location            = var.location
  resource_group_name = var.resourcegroup
  workspace_id        = azurerm_log_analytics_workspace.aks.id
  application_type    = "web"
}