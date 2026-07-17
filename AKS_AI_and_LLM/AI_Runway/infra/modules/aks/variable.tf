variable "location" {
}
variable "resourcegroup" {
}
variable "resourcegroup_id" {
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
variable "log_analytics_id" {
}
variable "identity_prefix" {
  description = "Prefix for the managed identity name"
  type        = string
}
variable "key_vault_id" {
}
variable "dns_prefix" {
}
variable "aks_subnet_id" {
}
variable "gpu_subnet_id" {
}
variable "lustre_mgs_address" {
}
variable "aks_infrence_tempname" {
  description = "Temporary name for the AKS inference node pool"
  type        = string
}