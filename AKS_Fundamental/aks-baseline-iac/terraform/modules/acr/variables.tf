variable "name" {
  description = "Name of the container registry"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku" {
  description = "SKU for ACR (Basic, Standard, Premium)"
  type        = string
  default     = "Premium"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
