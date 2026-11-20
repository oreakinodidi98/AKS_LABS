<#
.SYNOPSIS
Creates a basic AKS cluster for the workshop.
.DESCRIPTION
Requires Azure CLI, an active az login session, and permission to create resources
in the selected subscription. Uses Sweden Central and the region's default
Kubernetes version.

Creates a resource group and a single-node AKS cluster with a system-assigned
managed identity, Azure Linux, Azure CNI Overlay, and a public API endpoint.
Uses a manually sized cluster with the Free control-plane tier for this lab,
not AKS Automatic. Nodes, storage, and networking still incur charges.
No database, registry, monitoring workspace, or Key Vault is created.

Saves kubeconfig under your home directory, outside the repository, and selects
it for this PowerShell session. Requires kubectl to manage the cluster afterward.
If deployment fails, resources already created remain for inspection or cleanup.
.EXAMPLE
.\ClassicSetup.ps1
#>

$ErrorActionPreference = 'Stop'
Get-Command az -ErrorAction Stop | Out-Null

az account show --output none
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to access the Azure subscription. Run az login and select the intended subscription with az account set.'
}

$env:NAME_SUFFIX = "$(Get-Random)"
$env:LOCATION = 'swedencentral'
$env:RG_NAME = "rg-caldova$env:NAME_SUFFIX"
$env:AKS_CLUSTER_NAME = "aks-caldova-$env:NAME_SUFFIX"
$env:AKS_NAME = $env:AKS_CLUSTER_NAME

Write-Output "Creating resource group $env:RG_NAME in $env:LOCATION"
az group create --name $env:RG_NAME --location $env:LOCATION --output none
if ($LASTEXITCODE -ne 0) {
    throw "Failed to create resource group $env:RG_NAME."
}

Write-Output "Creating AKS cluster $env:AKS_NAME"
az aks create `
    --resource-group $env:RG_NAME `
    --name $env:AKS_NAME `
    --location $env:LOCATION `
    --tier free `
    --node-count 1 `
    --node-vm-size Standard_D2s_v5 `
    --os-sku AzureLinux `
    --network-plugin azure `
    --network-plugin-mode overlay `
    --enable-managed-identity `
    --generate-ssh-keys `
    --output none
if ($LASTEXITCODE -ne 0) {
    throw "Failed to create AKS cluster $env:AKS_NAME. Check the Azure CLI error above. Resource group: $env:RG_NAME."
}

$kubeconfigPath = Join-Path $HOME ".kube\$env:AKS_NAME.config"
az aks get-credentials `
    --resource-group $env:RG_NAME `
    --name $env:AKS_NAME `
    --file $kubeconfigPath
if ($LASTEXITCODE -ne 0) {
    throw "Cluster $env:AKS_NAME was created, but downloading its credentials failed. Retry az aks get-credentials for resource group $env:RG_NAME."
}

$env:KUBECONFIG = $kubeconfigPath
Write-Output "AKS cluster $env:AKS_NAME created. Kubeconfig saved to $kubeconfigPath"
Write-Output 'Check the cluster with: kubectl get nodes'
Write-Output "When finished, delete the lab resources with: az group delete --name $env:RG_NAME --yes --no-wait"
