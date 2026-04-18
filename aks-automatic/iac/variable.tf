# Default variables 
variable "resourcegroup" {
  description = "value for resourcegroup"
  type        = string
  default     = "tf_aks_automatic"
}
variable "location" {
  description = "value for location"
  type        = string
  default     = "UK South"
}
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    owner       = "Ore"
    environment = "AKS Automatic"
  }
}
variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}
variable "system_node_pool_vm_size" {
  description = "The size of the Virtual Machine."
  type        = string
  default     = "standard_D4lds_v5"
}

variable "system_node_pool_node_count" {
  description = "The initial quantity of nodes for the system node pool."
  type        = number
  default     = 3
}
variable "project_prefix" {
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
  type        = string
  default     = "aksautomaticdemo"
}
variable "resource_group_owner" {
  description = "The owner of the resource group."
  type        = string
  default     = "Ore"
}
#################### AKS Variables ####################
variable "aks_cluster_name" {
  type    = string
  default = "aks-terraform-automatic"
}
variable "acr_name" {
  type    = string
  default = "oaautomatic01"
}
variable "system_node_count" {
  description = "The number of system nodes for the AKS automatic cluster"
  type        = number
  default     = 3
}
variable "system_node_pool_vm_size" {
  description = "The size of the Virtual Machine."
  type        = string
  default     = "standard_D4lds_v5"
}
variable "identity_prefix" {
  description = "Prefix for the managed identity name"
  type        = string
  default     = "aksidentity"
}
variable "ssh_public_key" {
  description = "Path to SSH public key for AKS nodes"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}