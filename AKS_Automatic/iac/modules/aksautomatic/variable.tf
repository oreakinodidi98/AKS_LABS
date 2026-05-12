variable "location" {
}
variable "resourcegroup" {
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
}
 variable "resourcegroup_id" {
 }
variable "identity_prefix" {
  description = "Prefix for the managed identity name"
  type        = string
}
variable "key_vault_id" {
}
variable "project_prefix" {
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
  type        = string
}
variable "system_node_pool_vm_size" {
  description = "The size of the Virtual Machine."
  type        = string
}

variable "system_node_count" {
  description = "The initial quantity of nodes for the system node pool."
  type        = number
}
variable "resource_group_owner" {
  description = "The owner of the resource group."
  type        = string
}