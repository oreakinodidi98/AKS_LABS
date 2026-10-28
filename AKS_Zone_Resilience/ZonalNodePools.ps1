# General variables
$RAND = Get-Random
# Set it as an environment variable
$env:RAND = $RAND
# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"
# Set Location
$env:LOCATION = "swedencentral"
Write-Output "Location set to: $env:LOCATION"
# Resource group variables
$env:RG_NAME = "zonal$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# Azure account variables
$env:AZURE_SUBSCRIPTION_ID = az account show --query id -o tsv
Write-Output "Subscription ID: $env:AZURE_SUBSCRIPTION_ID"
$env:AZURE_TENANT_ID = az account show --query tenantId -o tsv
Write-Output "Tenant ID: $env:AZURE_TENANT_ID"
$subscriptionScope = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID"

# Networking variables
$env:vnet = "zonal-vnet"
$env:vnetPrefix = "10.50.0.0/16"
$env:systemSubnet = "system-subnet"
$env:systemSubnetPrefix = "10.50.1.0/24"
$env:userSubnet = "user-subnet"
$env:userSubnetPrefix = "10.50.2.0/24"
$env:podSubnet = "pod-subnet"
$env:podSubnetPrefix = "10.50.3.0/24"
$env:bastionSubnet = "AzureBastionSubnet"
$env:bastionSubnetPrefix = "10.50.4.0/24"
$env:myIp = (Invoke-RestMethod -Uri "https://api.ipify.org")
Write-Output "Current public IP: $env:myIp"

# AKS variables
$env:AKS_NAME = "myakscluster$RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"
# Get the latest Kubernetes version available in the region
$env:K8S_VERSION = $(az aks get-versions -l $env:LOCATION --query "values[?isDefault==``true``].version | [0]" -o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"
$env:systemNodePoolName = "systempool$RAND"
write-output "System node pool name: $env:systemNodePoolName"
$env:userNodePoolName = "userpool$RAND"
write-output "User node pool name: $env:userNodePoolName"
$env:vmSize = "Standard_DS2_v2"
write-output "Node pool VM size: $env:vmSize can also use Standard_D4ds_v4, Standard_F8s_v2, Standard_D4ads_v5"
$env:nodeCount = 2
write-output "Node count: $env:nodeCount"
$env:minCount = 2
write-output "Min count: $env:minCount"
$env:maxCount = 6
write-output "Max count: $env:maxCount"
$env:maxPods = 100
write-output "Max pods: $env:maxPods"


# Log Analytics variables
$env:WORKSPACE_NAME = "zonalworkspace$RAND"
Write-Output "Workspace name: $env:WORKSPACE_NAME"

# Create resource group
az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:RG_NAME created"

# create workspace
az monitor log-analytics workspace create --resource-group $env:RG_NAME --workspace-name $env:WORKSPACE_NAME --location $env:LOCATION
Write-Output "Workspace $env:WORKSPACE_NAME created"
# Get workspace ID 
$env:WORKSPACE_ID = az monitor log-analytics workspace show --resource-group $env:RG_NAME --workspace-name $env:WORKSPACE_NAME --query id -o tsv
Write-Output "Workspace ID: $env:WORKSPACE_ID"

# Create VNet with AKS subnet. This is the required networking.
az network vnet create -g $env:RG_NAME -n $env:vnet -l $env:LOCATION --address-prefixes $env:vnetPrefix `
  --subnet-name $env:systemSubnet --subnet-prefixes $env:systemSubnetPrefix
Write-Output "VNet and System subnet created."
# Get the subnet ID for the system subnet
$env:systemSubnetId = az network vnet subnet show -g $env:RG_NAME --vnet-name $env:vnet -n $env:systemSubnet --query id -o tsv
write-output "System subnet ID: $env:systemSubnetId"

# Create pod subnet in the same VNet.
az network vnet subnet create -g $env:RG_NAME --vnet-name $env:vnet -n $env:podSubnet `
  --address-prefixes $env:podSubnetPrefix
Write-Output "Pod subnet created in the same VNet."
# Get the subnet ID for the pod subnet
$env:podSubnetId = az network vnet subnet show -g $env:RG_NAME --vnet-name $env:vnet -n $env:podSubnet --query id -o tsv
write-output "Pod subnet ID: $env:podSubnetId"

# Create user subnet in the same VNet.
az network vnet subnet create -g $env:RG_NAME --vnet-name $env:vnet -n $env:userSubnet `
  --address-prefixes $env:userSubnetPrefix
Write-Output "User subnet created in the same VNet."
# Get the subnet ID for the user subnet
$env:userSubnetId = az network vnet subnet show -g $env:RG_NAME --vnet-name $env:vnet -n $env:userSubnet --query id -o tsv
write-output "User subnet ID: $env:userSubnetId"

# Create bastion subnet in the same VNet.
az network vnet subnet create -g $env:RG_NAME --vnet-name $env:vnet -n $env:bastionSubnet `
  --address-prefixes $env:bastionSubnetPrefix
Write-Output "Bastion subnet created in the same VNet."
# Get the subnet ID for the bastion subnet
$env:bastionSubnetId = az network vnet subnet show -g $env:RG_NAME --vnet-name $env:vnet -n $env:bastionSubnet --query id -o tsv
write-output "Bastion subnet ID: $env:bastionSubnetId"

# Create AKS cluster with zone-redundant system node pools
az aks create -g $env:RG_NAME -n $env:AKS_NAME `
  --location $env:LOCATION `
  --kubernetes-version $env:K8S_VERSION `
  --enable-managed-identity `
  --enable-oidc-issuer `
  --enable-aad `
  --enable-azure-rbac `
  --enable-workload-identity `
  --enable-addons monitoring `
  --workspace-resource-id $env:WORKSPACE_ID `
  --nodepool-name $env:systemNodePoolName `
  --node-count $env:nodeCount `
  --min-count $env:minCount `
  --max-count $env:maxCount `
  --max-pods $env:maxPods `
  --enable-cluster-autoscaler `
  --node-vm-size $env:vmSize `
  --vnet-subnet-id $env:systemSubnetId `
  --pod-subnet-id $env:podSubnetId `
  --network-policy azure `
  --network-plugin azure `
  --nodepool-taints CriticalAddonsOnly=true:NoSchedule `
  --nodepool-labels nodePoolMode=system created=AzureCLI osDiskType=ephemeral  `
  --cluster-autoscaler-profile balance-similar-node-groups=true `
  --tags created=AzureCLI `
  --zones 1 2 `
  --only-show-errors
write-output "AKS cluster $env:AKS_NAME created with zone-redundant system node pools."

# create user node pools
az aks nodepool add -g $env:RG_NAME -n $env:userNodePoolName --cluster-name $env:AKS_NAME `
  --node-count $env:nodeCount `
  --min-count $env:minCount `
  --max-count $env:maxCount `
  --max-pods $env:maxPods `
  --eviction-policy Delete `
  --enable-cluster-autoscaler `
  --node-vm-size $env:vmSize `
  --vnet-subnet-id $env:userSubnetId `
  --pod-subnet-id $env:podSubnetId `
  --network-policy azure `
  --network-plugin azure `
  --nodepool-labels nodePoolMode=user created=AzureCLI osDiskType=ephemeral osType=Linux `
  --nodepool-tags osDiskType=ephemeral osDiskType=ephemeral osType=Linux `
  --tags created=AzureCLI osDiskType=managed osType=Linux `
  --labels nodePoolMode=user created=AzureCLI osDiskType=ephemeral osType=Linux --tags osDiskType=ephemeral osDiskType=ephemeral osType=Linux `
  --zones 1 2
write-output "User node pool $env:userNodePoolName created with zone-redundant node pools."

# Set kubeconfig path and connect to the cluster
az aks get-credentials -g $env:RG_NAME -n $env:AKS_NAME --overwrite-existing
write-output "Connected to AKS cluster $env:AKS_NAME"

$env:KUBELET_OBJECT_ID = $(az aks show --name $env:AKS_NAME --resource-group $env:RG_NAME --query identityProfile.kubeletidentity.objectId --output tsv)
Write-Output "KUBELET_OBJECT_ID: $env:KUBELET_OBJECT_ID"