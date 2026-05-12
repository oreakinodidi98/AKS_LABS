resource "random_string" "suffix" {
  length = 6
  special = false
  upper = false
}
# get latest azure AKS latest Version
data "azurerm_kubernetes_service_versions" "versions" {
    location = var.location
    include_preview = false
}
data "azurerm_subscription" "current" {}
#create managed identity
resource "azurerm_user_assigned_identity" "aks_cluster" {
  name                = var.identity_prefix
  location            = var.location
  resource_group_name = var.resourcegroup
}
#create role assighnment at RG scope with managed identity
resource "azurerm_role_assignment" "role_rg" {
  scope                = var.resourcegroup_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_cluster.principal_id
}
# create role assignment at subscription scope with managed identity
resource "azurerm_role_assignment" "contributor_role_assignment" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_cluster.principal_id
}
#create acr
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resourcegroup
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = false
}
#create role assignment for acr pull with managed identity
resource "azurerm_role_assignment" "mi_role_acrpull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aks_cluster.principal_id
  skip_service_principal_aad_check = true
}
# Role Assignment for AKS Key Vault Secrets Provider identity
resource "azurerm_role_assignment" "aks_kv_secrets_user" {
  #scope                = azurerm_key_vault.main.id
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.key_vault_secrets_provider[0].secret_identity[0].object_id
}
resource "azapi_resource" "aks_auto" {
  type      = "Microsoft.ContainerService/managedClusters@2024-06-02-preview"
  name      = "aks-${var.aks_cluster_name}-${random_string.suffix.result}"
  parent_id = var.resourcegroup.id
  location  = var.location
  tags     = azurerm_resource_group.rg.tags
  
  body = jsonencode({

    properties = {
      kubernetesVersion = data.azurerm_kubernetes_service_versions.versions.latest_version
      nodeResourceGroup = "${var.resourcegroup}-node-rg-${random_string.suffix.result}"
      agentPoolProfiles = [
        {
          name    = "systempool"
          count   = var.system_node_count
          vmSize  = var.system_node_pool_vm_size
          tags    = { owner = var.resource_group_owner }
          mode    = "System"
          osType  = "Linux"
          osSKU   = "AzureLinux"
          osDiskSizeGB = 64
          enableAutoScaling = false
        }
      ]
      linuxProfile = {
        adminUsername = var.username
        ssh = {
          publicKeys = [
            {
              keyData = tls_private_key.ssh_key.public_key_openssh
            }
          ]
        }
      }

      azureMonitorProfile = {
        metrics = {
          enabled = true
          kubeStateMetrics = {
            metricAnnotationsAllowList = var.ksm_allowed_annotations
            metricLabelsAllowlist = var.ksm_allowed_labels
          }
        }
      }
    }

    identity = {
      type = "SystemAssigned"
    }

    sku = {
      name     = "Automatic"
      tier    = "Standard"
    }
  })
}