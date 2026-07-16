variable "location" {
  description = "The location of the resources"
  type        = string
}
variable "resourcegroup" {
  description = "The name of the resource group"
  type        = string
}
variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
}
variable "lustre_name" {
  description = "The name of the Lustre file system"
  type        = string
}
variable "lustre_sku_name" {
  description = "The SKU name of the Lustre file system"
  type        = string
}