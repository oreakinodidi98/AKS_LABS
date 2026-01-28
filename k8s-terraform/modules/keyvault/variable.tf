variable "resourcegroup" {
  description = "Name of the resource group"
  type        = string
}
variable "kv_name" {
  description = "Name of the Key Vault"
  type        = string
}
variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "tenant_id" {
  description = "The Azure AD tenant ID"
  type        = string
}

variable "object_id" {
  description = "The object ID of the current user/service principal"
  type        = string
}

variable "backend_identity_principal_id" {
  description = "Principal ID of the backend managed identity"
  type        = string
  default     = null
}
variable "identity_prefix" {
  description = "Prefix for the managed identity name"
  type        = string
}