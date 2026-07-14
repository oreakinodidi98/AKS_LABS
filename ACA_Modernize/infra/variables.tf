# Default variables 
variable "resourcegroup" {
  description = "value for resourcegroup"
  type        = string
  default     = "tf_aca_demo"
}
variable "location" {
  description = "value for location"
  type        = string
  default     = "swedencentral"
}
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    owner       = "Ore"
    environment = "ACA Terraform"
  }
}
variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}
variable "foundry_name" {
  description = "Name of the Foundry resource"
  type        = string
  default     = "tf-foundry-orea629a1"
}
variable "foundry_project_name" {
  description = "Name of the Foundry project"
  type        = string
  default     = "tf-foundry-project-orea629a1"
}
variable "custom_subdomain_name" {
  description = "Custom subdomain name for the Foundry project"
  type        = string
  default     = "foundry-orea629a1"
}
variable "cosmos_name" {
  description = "Name of the Cosmos DB account"
  type        = string
  default     = "cosmosdbagentmemorea629a1"
}
variable "cosmos_kind" {
  description = "Kind of the Cosmos DB account"
  type        = string
  default     = "GlobalDocumentDB"
}

variable "cosmos_offer_type" {
  description = "Offer type of the Cosmos DB account"
  type        = string
  default     = "Standard"
}

variable "plan_name" {
  description = "Name of the App Service plan"
  type        = string
  default     = "app-service-plan-mcp-server"
}

variable "appservice_name" {
  description = "Name of the App Service"
  type        = string
  default     = "mcp-open-web-search-orea629a1"
}

variable "os_type" {
  description = "Operating system type for the App Service (e.g., Linux, Windows)"
  type        = string
  default     = "Linux"
}

variable "sku_kind" {
  description = "SKU kind of the App Service plan"
  type        = string
  default     = "B1"
}

variable "environment_name" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "aca-environment"
}
variable "aca_name" {
  description = "Name of the Azure Container Apps environment"
  type        = string
  default     = "aca-demo-environment"
}

variable "aca_session_pool_shell" {
  description = "Name of the Azure Container Apps session pool for shell"
  type        = string
  default     = "aca-sessionpool-shell-400"
}

variable "aca_session_pool_python" {
  description = "Name of the Azure Container Apps session pool for Python"
  type        = string
  default     = "aca-sessionpool-python-400"
}
