variable "env_name" {
  description = "Environment name prefix for resources"
  type        = string
}
variable "location" {
  description = "Azure region for resources"
  type        = string
}
variable "resourcegroup" {
  description = "Resource group name"
  type        = string
}
variable "log_analytics_workspace_sku" {
  description = "SKU for Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"
}
variable "app_insights_name" {
  description = "Name prefix for Application Insights"
  type        = string
  default     = "appinsights"
}