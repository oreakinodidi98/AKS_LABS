variable "server_name" {
  description = "Name of the SQL Server"
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

variable "admin_username" {
  description = "Administrator username"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Administrator password"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the SQL database"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
