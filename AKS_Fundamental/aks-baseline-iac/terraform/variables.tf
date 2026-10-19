variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "aks-baseline"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.28"
}

variable "aks_system_node_count" {
  description = "Number of nodes in system node pool"
  type        = number
  default     = 3
}

variable "aks_user_node_count" {
  description = "Number of nodes in user node pool"
  type        = number
  default     = 3
}

variable "aks_system_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "aks_user_vm_size" {
  description = "VM size for user node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "vnet_address_space" {
  description = "Address space for virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "appgw_subnet_address_prefix" {
  description = "Address prefix for Application Gateway subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "sqladmin"
  sensitive   = true
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

variable "enable_private_cluster" {
  description = "Enable private AKS cluster"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "AKS-Baseline"
  }
}
