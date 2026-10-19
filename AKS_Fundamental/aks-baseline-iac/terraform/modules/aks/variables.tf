variable "cluster_name" {
  description = "Name of the AKS cluster"
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

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vnet_subnet_id" {
  description = "ID of the subnet for AKS"
  type        = string
}

variable "system_node_count" {
  description = "Number of nodes in system pool"
  type        = number
  default     = 3
}

variable "system_vm_size" {
  description = "VM size for system pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "user_node_count" {
  description = "Number of nodes in user pool"
  type        = number
  default     = 3
}

variable "user_vm_size" {
  description = "VM size for user pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "managed_identity_id" {
  description = "ID of the managed identity"
  type        = string
}

variable "managed_identity_client_id" {
  description = "Client ID of the managed identity"
  type        = string
}

variable "enable_private_cluster" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
