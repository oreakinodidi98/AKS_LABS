# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND

# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"

# Set Location
$env:LOCATION = "uksouth"
Write-Output "Location set to: $env:LOCATION"

# set subscription
$env:SUBSCRIPTION_ID=$(az account show --query id -o tsv)
write-Output "Subscription ID set to: $env:SUBSCRIPTION_ID"

# Resource name

$env:RUN_ID = "{0:x4}" -f (Get-Random -Maximum 65536)
write-Output "Run ID set to: $env:RUN_ID"
$env:CUSTOMER_RG_NAME = "hcphackrg-$($env:USERNAME)-$($env:RUN_ID)"
write-Output "Resource group name set to: $env:CUSTOMER_RG_NAME"
$env:CUSTOMER_NSG="aro-hcp-nsg"
write-Output "Network security group name set to: $env:CUSTOMER_NSG"
$env:CUSTOMER_VNET_NAME="aro-hcp-vnet"
write-Output "Virtual network name set to: $env:CUSTOMER_VNET_NAME"
$env:CUSTOMER_VNET_SUBNET1="aro-hcp-worker-subnet"
write-Output "Worker subnet name set to: $env:CUSTOMER_VNET_SUBNET1"
$env:CUSTOMER_VNET_INTEGRATION_SUBNET_NAME="aro-hcp-vnet-integration-subnet"
write-Output "Integration subnet name set to: $env:CUSTOMER_VNET_INTEGRATION_SUBNET_NAME"
$env:CUSTOMER_KEYVAULT_NAME = "custkv$([guid]::NewGuid().ToString('N').Substring(0,12).ToLower())"
write-Output "Key Vault name set to: $env:CUSTOMER_KEYVAULT_NAME"

# cluster config

$env:CLUSTER_NAME="hcphack-$($env:USERNAME)-$($env:RUN_ID)"
write-Output "Cluster name set to: $env:CLUSTER_NAME"
$env:MANAGED_RESOURCE_GROUP="${env:CLUSTER_NAME}-managed-rg"
write-Output "Managed resource group name set to: $env:MANAGED_RESOURCE_GROUP" 
$env:NP_NAME="np-1" 
write-Output "Node pool name set to: $env:NP_NAME"

# Versions 
$env:API_VERSION="2025-12-23-preview" 
$env:CLUSTER_VERSION="4.20"
$env:NP_VERSION="4.20.21"

# login to az cli
az login

# register the ARO resource provider
az provider register -n Microsoft.RedHatOpenShift --wait
az provider register -n Microsoft.Compute --wait
az provider register -n Microsoft.Storage --wait
az provider register -n Microsoft.Authorization --wait

# verify registration
az provider show --namespace Microsoft.RedHatOpenShift --query "registrationState" -o tsv

# validate HCP resource type availability in this subscription
$hcpType = az provider show --namespace Microsoft.RedHatOpenShift --query "resourceTypes[?resourceType=='hcpOpenShiftClusters'].resourceType | [0]" -o tsv
if ([string]::IsNullOrWhiteSpace($hcpType)) {
  Write-Error "This subscription does not expose Microsoft.RedHatOpenShift/hcpOpenShiftClusters. Available type is OpenShiftClusters only. Use an HCP-enabled subscription/region or switch to a classic ARO (OpenShiftClusters) template."
  exit 1
}

# check quota for ARO clusters
az vm list-usage --location $env:LOCATION -o table
Write-Output "Please ensure you have sufficient quota for the following resources in the $env:LOCATION region"

# create a resource group
az group create `
  --name $env:CUSTOMER_RG_NAME `
  --subscription "$env:SUBSCRIPTION_ID" `
  --location $env:LOCATION

# deploy bicep file
az deployment group create `
  --name "aro-hcp" `
  --resource-group $env:CUSTOMER_RG_NAME `
  --template-file azuredeploy.bicep `
  --parameters customerNsgName="$env:CUSTOMER_NSG" `
  customerVnetName="$env:CUSTOMER_VNET_NAME" `
  customerVirtualNetworkIntegrationSubnetName="$env:CUSTOMER_VNET_INTEGRATION_SUBNET_NAME" `
  customerVnetSubnetName="$env:CUSTOMER_VNET_SUBNET1" `
  customerKeyVaultName="$env:CUSTOMER_KEYVAULT_NAME" `
  clusterName="$env:CLUSTER_NAME" `
  managedResourceGroupName="$env:MANAGED_RESOURCE_GROUP" `
  nodePoolName="$env:NP_NAME" `
  clusterVersion="$env:CLUSTER_VERSION" `
  nodePoolVersion="$env:NP_VERSION" `
  privateKeyVault=false `
  --subscription "$env:SUBSCRIPTION_ID"

# verify deployment
$env:clusterUri = "/subscriptions/$($env:SUBSCRIPTION_ID)/resourceGroups/$($env:CUSTOMER_RG_NAME)/providers/Microsoft.RedHatOpenShift/hcpOpenShiftClusters/$($env:CLUSTER_NAME)?api-version=$($env:API_VERSION)"
az rest `
  --method GET `
  --uri $env:clusterUri `
  --query "{name:name, provisioningState:properties.provisioningState, version:properties.version}"