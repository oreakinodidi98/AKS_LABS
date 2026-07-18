# Default variables 
variable "resourcegroup" {
  description = "value for resourcegroup"
  type        = string
  default     = "rg_ai_runway"
}
variable "location" {
  description = "value for location"
  type        = string
  default     = "uksouth"
}
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    owner       = "Ore"
    environment = "AI Runway"
  }
}
variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}
#################### KV Variables ####################
variable "kv_name" {
  description = "Name of the Key Vault"
  type        = string
  default     = "tfkeyvaultairunway"
}
#################### AKS Variables ####################
variable "aks_cluster_name" {
  type    = string
  default = "aks-airrunway"
}
variable "acr_name" {
  type    = string
  default = "acrairunway"
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
variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "aks-airunway"
}
variable "aks_infrence_tempname" {
  description = "Temporary name for the AKS inference node pool"
  type        = string
  default     = "temp"
}
variable "enable_gpu_inference_pool" {
  description = "Whether to deploy the GPU inference node pool and GPU operator"
  type        = bool
  default     = true
}
#################### Logs Variables ####################
variable "env_name" {
  description = "Name of Environment"
  type        = string
  default     = "ai-k8sdemo"
}
variable "log_analytics_workspace_sku" {
  description = "The pricing SKU of the Log Analytics workspace."
  default     = "PerGB2018"
}
variable "app_insights_name" {
  description = "Name of the Application Insights"
  type        = string
  default     = "tfappinsightsai"
}
#################### Networking Variables ####################
variable "vnet_name" {
  type    = string
  default = "vnet-airunway"
}
variable "lustre_name" {
  description = "The name of the Lustre file system"
  type        = string
  default     = "lustre-airunway"
}
variable "lustre_sku_name" {
  description = "The SKU name of the Lustre file system"
  type        = string
  default     = "AMLFS-Durable-Premium-500"
}







