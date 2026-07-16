terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.46.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.25.2"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "=3.1.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "=0.13.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "=1.19.0"
    }
  }
  #initialise the backend
  backend "azurerm" {
    resource_group_name  = "tfstaterg01"
    storage_account_name = "tfstate01919804057"
    container_name       = "tfstate2"
    key                  = "aks_ai_runway.tfstate"
    use_azuread_auth     = true
  }

}
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}
provider "azapi" {}
provider "helm" {
  kubernetes = {
    host                   = azurerm_kubernetes_cluster.example.kube_config.0.host
    username               = azurerm_kubernetes_cluster.example.kube_config.0.username
    password               = azurerm_kubernetes_cluster.example.kube_config.0.password
    client_certificate     = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate)
  }
}
provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.example.kube_config.0.host
  username               = azurerm_kubernetes_cluster.example.kube_config.0.username
  password               = azurerm_kubernetes_cluster.example.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate)
  load_config_file       = false
}