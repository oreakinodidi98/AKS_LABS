
variable "location" {
  description = "Azure region for resources"
  type        = string
}
variable "resourcegroup" {
  description = "Name of the resource group"
  type        = string
}
variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}
variable "aks_cluster_name" {
  type = string
}
variable "acr_name" {
  type = string
}
variable "system_node_count" {
  description = "The number of system nodes for the AKS cluster"
  type        = number
}
variable "log_analytics_id" {
  description = "Resource ID of the Log Analytics workspace"
  type        = string
}
variable "resourcegroup_id" {
  description = "Resource ID of the resource group"
  type        = string
}
variable "identity_prefix" {
  description = "Prefix for the managed identity name"
  type        = string
}
variable "aks_subnet_id" {
  description = "Resource ID of the AKS subnet"
  type        = string
}
variable "appgateway_subnet_id" {
  description = "Resource ID of the Application Gateway subnet"
  type        = string
}
variable "pip_name" {
  description = "Name of the public IP"
  type        = string
}
variable "appgateway_name" {
  description = "Name of the application gateway"
  type        = string
}