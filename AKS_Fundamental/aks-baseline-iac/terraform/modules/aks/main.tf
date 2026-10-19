resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  private_cluster_enabled = var.enable_private_cluster

  default_node_pool {
    name                = "system"
    node_count          = var.system_node_count
    vm_size             = var.system_vm_size
    vnet_subnet_id      = var.vnet_subnet_id
    type                = "VirtualMachineScaleSets"
    orchestrator_version = var.kubernetes_version
    
    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.vnet_subnet_id
  orchestrator_version  = var.kubernetes_version
  
  upgrade_settings {
    max_surge = "10%"
  }

  tags = var.tags
}
