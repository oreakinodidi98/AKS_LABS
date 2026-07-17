terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "=1.19.0"
    }
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
  dns_prefix          = var.dns_prefix
  kubernetes_version = data.azurerm_kubernetes_service_versions.versions.latest_version
  node_resource_group = "${var.resourcegroup}-node-rg"

  default_node_pool {
    name       = "systempool"
    min_count            = 3
    max_count            = 6
    temporary_name_for_rotation = "temppool"
      enable_auto_scaling  = true
    vm_size              = "Standard_D4d_v4"
    # Node taints for system pool
    only_critical_addons_enabled = true
    vnet_subnet_id = var.aks_subnet_id 
    node_labels         = {
      "nodepool" = "systempool"
      "env"      = "aks-ai-runway"
    }
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
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
      "env"      = "AKS AI Runway"
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
}

resource "helm_release" "nvidia_gpu_operator" {
  name             = "gpu-operator"
  repository       = "https://helm.ngc.nvidia.com/nvidia"
  chart            = "gpu-operator"
  version          = "v26.3.1"
  namespace        = "gpu-operator"
  create_namespace = true
}

resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = "1.29.2"
  namespace        = "istio-system"
  create_namespace = true
}

resource "helm_release" "istiod" {
  name             = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = "1.29.2"
  namespace        = "istio-system"
  create_namespace = false

  set = [
    {
      name  = "pilot.env.ENABLE_GATEWAY_API_INFERENCE_EXTENSION"
      value = "true"
    },
  ]

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "argo_cd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.5.4"
  namespace        = "argocd"
  create_namespace = true
}

resource "kubectl_manifest" "argo_cd_app" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = "app-of-apps"
      namespace  = "argocd"
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/oreakinodidi98/AKS_LABS.git"
        targetRevision = "HEAD"
        path           = "AKS_AI_and_LLM/AI_Runway/manifests/argocd/apps"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  })

  depends_on = [
    azurerm_kubernetes_cluster.aks_cluster,
    helm_release.argo_cd
  ]
}

resource "kubectl_manifest" "azurelustre_storageclass" {
  yaml_body = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "azurelustre-static"
    }
    provisioner = "azurelustre.csi.azure.com"
    parameters = {
      "mgs-ip-address" = var.lustre_mgs_address
    }
    reclaimPolicy     = "Retain"
    volumeBindingMode = "Immediate"
    mountOptions = [
      "noatime",
      "flock"
    ]
  })
  depends_on = [
    azurerm_kubernetes_cluster.aks_cluster,
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "inference" {
  name                        = "inference"
  kubernetes_cluster_id       = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size                     = "Standard_NC48ads_A100_v4"
  node_count                  = 1
  min_count                   = 1
  max_count                   = 1
  enable_auto_scaling         = true
  vnet_subnet_id              = var.gpu_subnet_id

  upgrade_settings {
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks_cluster,
    helm_release.nvidia_gpu_operator,
    helm_release.istio_base,
    helm_release.istiod,
    helm_release.argo_cd,
    kubectl_manifest.argo_cd_app
  ]
}