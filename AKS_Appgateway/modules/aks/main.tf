locals {
  backend_address_pool_name      = "backend_address_pool"
  frontend_port_name             = "frontend_port"
  frontend_ip_configuration_name = "frontend_ip_configuration"
  http_setting_name              = "http_setting"
  listener_name                  = "listener"
  request_routing_rule_name      = "request_routing_rule"
  redirect_configuration_name    = "redirect_configuration"
}

resource "azurerm_public_ip" "pip-appgateway" {
  name                = var.pip_name
  resource_group_name = var.resourcegroup
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgateway" {
  name                = var.appgateway_name
  resource_group_name = var.resourcegroup
  location            = var.location

  sku {
    name     = "Standard_v2" # "WAF_v2"
    tier     = "Standard_v2" # "WAF_v2"
    capacity = 1
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip-appgateway.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = ["10.10.1.10"] # ["10.10.0.10"] # IP address of the exposed private ingress service
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.appgateway_subnet_id
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  probe {
    name                                      = "http-health-probe"
    protocol                                  = "Http"
    pick_host_name_from_backend_http_settings = true
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    minimum_servers                           = 0
  }
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
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity.0.principal_id
}
# create role assignment at subscription scope with managed identity
resource "azurerm_role_assignment" "contributor_role_assignment" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity.0.principal_id
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
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity.0.principal_id
  skip_service_principal_aad_check = true
}

# create AKS cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resourcegroup
  dns_prefix          = replace("${var.resourcegroup}-cluster", "_", "-")
  kubernetes_version = data.azurerm_kubernetes_service_versions.versions.latest_version
  private_cluster_enabled = false
  node_resource_group = "${var.resourcegroup}-node-rg"

  default_node_pool {
    name       = "systempool"
    os_sku              = "AzureLinux"
    temporary_name_for_rotation = "temppool"
    vm_size    = "Standard_A2_v2"
    node_count = var.system_node_count
    vnet_subnet_id  = var.aks_subnet_id
    # Node taints for system pool
    only_critical_addons_enabled = true
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

  # # Key Vault Secrets Provider addon
  # key_vault_secrets_provider {
  #   secret_rotation_enabled = true
  # }

  # # Azure Monitor for containers
  # monitor_metrics {
  #   annotations_allowed = null
  #   labels_allowed      = null
  # }

  web_app_routing {
    dns_zone_ids = []
    # default_nginx_controller = "Internal"
  }
  network_profile {
        network_plugin = "azure"
        network_plugin_mode = "overlay"
        network_policy      = "cilium"
        network_data_plane  = "cilium"
        outbound_type       = "loadBalancer"
        load_balancer_sku   = "standard"
    }
    lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
    ]
  }
}

# Role Assignment for AKS Key Vault Secrets Provider identity
resource "azurerm_role_assignment" "network-contributor" {
  #scope                = azurerm_subnet.snet-aks-lb.id # azurerm_virtual_network.vnet-spoke.id
  scope                = var.aks_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity.0.principal_id
}

resource "terraform_data" "aks-get-credentials" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks_cluster.id
  ]

  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.aks_cluster.name} -g ${azurerm_kubernetes_cluster.aks_cluster.resource_group_name} --overwrite-existing"
  }
}

