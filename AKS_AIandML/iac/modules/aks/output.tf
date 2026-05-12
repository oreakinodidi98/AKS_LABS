locals {
  client_certificate_path = "${abspath(path.module)}/azurek8s.crt"
  kube_config_path        = "${abspath(path.module)}/azurek8s.config"
}
#output acr id
output "acr_id" {
    description = "value for acr id"
    value = azurerm_container_registry.acr.id
}
#output acr login server
output "acr_login_server" {
    description = "value for acr login server"
    value = azurerm_container_registry.acr.login_server
}
#output acr name
output "acr_name" {
    description = "value for acr name"
    value = azurerm_container_registry.acr.name
}
#output aks name
output "aks_name" {
    description = "value for aks name"
    value = azurerm_kubernetes_cluster.aks_cluster.name
}
#output aks object id
output "aks_id" {
    description = "value for aks id"
    value = azurerm_kubernetes_cluster.aks_cluster.id
}
#output aks fqdn
output "aks_fqdn" {
    description = "value for aks fqdn"
    value = azurerm_kubernetes_cluster.aks_cluster.fqdn
}
#output aks node resource group
output "aks_node_resource_group" {
    description = "value for aks node resource group"
    value = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
}
# kube config local file system output
resource "local_file" "kube_config" {
  content  = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  filename = local.kube_config_path
   depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}
# # kube config certificate
# resource "local_file" "client_certificate" {
#   content  = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate)
#   filename = local.client_certificate_path
#    depends_on = [azurerm_kubernetes_cluster.aks]
# }
#output aks kube config path
output "kube_config_path" {
  value = local.kube_config_path
}
#output aks kube config instructions
output "recommend_kube_config" {
  value = <<EOF
  # run this command in bash to use the new AKS clusters
export KUBECONFIG=${local.kube_config_path}
# or in PowerShell
$KUBECONFIG = "${local.kube_config_path}"
EOF
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate
  sensitive = true
}

output "client_key" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "cluster_password" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].password
  sensitive = true
}

output "cluster_username" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].username
  sensitive = true
}
output "host" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
  sensitive = true
}
output "system_node_pool_name" {
  value = azurerm_kubernetes_cluster.aks_cluster.default_node_pool[0].name
}
########################## output for managed identity ##############################
output "managed_identity_client_id" {
  value = azurerm_user_assigned_identity.aks_cluster.client_id
}
output "managed_identity_principal_id" {
  value = azurerm_user_assigned_identity.aks_cluster.principal_id
}