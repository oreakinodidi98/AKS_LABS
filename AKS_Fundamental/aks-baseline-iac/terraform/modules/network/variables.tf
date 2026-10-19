variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "aks_subnet_name" {
  description = "Name of the AKS subnet"
  type        = string
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
}

variable "appgw_subnet_name" {
  description = "Name of the Application Gateway subnet"
  type        = string
}

variable "appgw_subnet_address_prefix" {
  description = "Address prefix for Application Gateway subnet"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
