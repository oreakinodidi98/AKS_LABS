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
# create AKS cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resourcegroup
  dns_prefix          = replace("${var.resourcegroup}-cluster", "_", "-")
  kubernetes_version = data.azurerm_kubernetes_service_versions.versions.latest_version
  node_resource_group = "${var.resourcegroup}-node-rg"

  default_node_pool {
    name       = "systempool"
    os_sku              = "AzureLinux"
    temporary_name_for_rotation = "temppool"
    vm_size    = "Standard_A2_v2"
    # Node taints for system pool
    only_critical_addons_enabled = true
    node_count = var.system_node_count
    #vnet_subnet_id = var.aks_subnet_id 
    node_labels         = {
      "nodepool" = "systempool"
      "env"      = "AKS Mod"
    }
  }
identity {
    type = "SystemAssigned"
  }
  # Monitoring addon
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_id
  }
  tags = {
      "nodepool" = "system"
      "env"      = "AKS Mod"
  }
  # OIDC and Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Key Vault Secrets Provider addon
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  # Azure Monitor for containers
  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }
  
  linux_profile {
    admin_username = "ubuntu"
    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }
    network_profile {
        network_plugin = "azure"
        network_plugin_mode = "overlay"
        network_policy      = "cilium"
        network_data_plane  = "cilium"
        load_balancer_sku   = "standard"
        pod_cidr            = "10.244.0.0/16"
        service_cidr        = "172.16.0.0/16"
        dns_service_ip      = "172.16.0.10"
    }
    lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
    ]
  }
}

# Enable ACNS features using AzAPI (for features not yet in AzureRM)
resource "azapi_update_resource" "aks_acns" {
  type        = "Microsoft.ContainerService/managedClusters@2024-05-01"
  resource_id = azurerm_kubernetes_cluster.aks_cluster.id

  body = jsonencode({
    properties = {
      networkProfile = {
        advancedNetworking = {
          enabled = true
          observability = {
            enabled = true
          }
          security = {
            fqdnPolicy = {
              enabled = true
            }
          }
        }
      }
    }
  })

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}
# User Node Pool
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size               = "Standard_A2_v2"
  node_count            = 1
  mode                  = "User"
  os_sku                = "AzureLinux"

  depends_on = [azapi_update_resource.aks_acns]
}