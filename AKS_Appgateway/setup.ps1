#### Step 1 Define Environment Variables ####

$env:RANDOM_ID="$(openssl rand -hex 3)"
Write-Output "Random ID: $env:RANDOM_ID"
$env:RESOURCE_GROUP_NAME="tf_aks_appgw"
Write-Output "Resource Group Name: $env:RESOURCE_GROUP_NAME"
$env:REGION="uksouth"
Write-Output "Region: $env:REGION"
$env:AKS_CLUSTER_NAME="aks-terraform-appgw"
Write-Output "AKS Cluster Name: $env:AKS_CLUSTER_NAME"
$env:ACR_NAME="oatfmod01$env:RANDOM_ID"
Write-Output "ACR Name: $env:ACR_NAME"
$env:VNET_NAME="$env:RESOURCE_GROUP_NAME-vnet-spoke"
Write-Output "VNet Name: $env:VNET_NAME"
$env:LOG_WORKSPACE_NAME="mi-k8sdemo-loga$env:RANDOM_ID"
Write-Output "Log Analytics Workspace Name: $env:LOG_WORKSPACE_NAME"
$env:MONITOR_WORKSPACE_NAME="mi-k8sdemo-monitor"
Write-Output "Monitor Workspace Name: $env:MONITOR_WORKSPACE_NAME"
$env:APP_INSIGHTS_NAME="tfappinsight$env:RANDOM_ID"
Write-Output "App Insights Name: $env:APP_INSIGHTS_NAME"
$env:PIP_NAME="appgw-pip"
Write-Output "Public IP Name: $env:PIP_NAME"
$env:APPGW_NAME="appgw-terraform"
Write-Output "App Gateway Name: $env:APPGW_NAME"
$env:IDENTITY_NAME="aksidentity"
Write-Output "Managed Identity Name: $env:IDENTITY_NAME"
$env:VM_NAME="$env:RESOURCE_GROUP_NAME-vm-linux-jumpbox"
Write-Output "VM Name: $env:VM_NAME"
$env:NIC_NAME="$env:RESOURCE_GROUP_NAME-nic-vm-linux"
Write-Output "NIC Name: $env:NIC_NAME"
$env:VM_ADMIN_PASSWORD="$(openssl rand -base64 20)"
Write-Output "VM Admin Password generated"

#### Step 2 Create Resource Group ####

az group create --name $env:RESOURCE_GROUP_NAME --location $env:REGION
Write-Output "Resource group $env:RESOURCE_GROUP_NAME created"

#### Step 3 Create Virtual Network and Subnets ####

az network vnet create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:VNET_NAME `
  --address-prefix 10.10.0.0/16 `
  --location $env:REGION
Write-Output "VNet $env:VNET_NAME created"

az network vnet subnet create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --vnet-name $env:VNET_NAME `
  --name snet-aks `
  --address-prefixes 10.10.0.0/24
Write-Output "Subnet snet-aks created"

az network vnet subnet create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --vnet-name $env:VNET_NAME `
  --name snet-aks-lb `
  --address-prefixes 10.10.1.0/24
Write-Output "Subnet snet-aks-lb created"

az network vnet subnet create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --vnet-name $env:VNET_NAME `
  --name snet-appgateway `
  --address-prefixes 10.10.2.0/24
Write-Output "Subnet snet-appgateway created"

az network vnet subnet create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --vnet-name $env:VNET_NAME `
  --name snet-vm `
  --address-prefixes 10.10.3.0/24
Write-Output "Subnet snet-vm created"

#### Step 4 Create Log Analytics Workspace ####

az monitor log-analytics workspace create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
  --location $env:REGION `
  --sku PerGB2018
Write-Output "Log Analytics Workspace $env:LOG_WORKSPACE_NAME created"

$env:LOG_WORKSPACE_ID = az monitor log-analytics workspace show `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
  --query "id" -o tsv
Write-Output "Log Analytics Workspace ID: $env:LOG_WORKSPACE_ID"

#### Step 5 Create Azure Monitor Workspace ####

az monitor account create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:MONITOR_WORKSPACE_NAME `
  --location $env:REGION
Write-Output "Azure Monitor Workspace $env:MONITOR_WORKSPACE_NAME created"

#### Step 6 Create Application Insights ####

az monitor app-insights component create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --app $env:APP_INSIGHTS_NAME `
  --location $env:REGION `
  --kind web `
  --application-type web `
  --workspace $env:LOG_WORKSPACE_ID
Write-Output "Application Insights $env:APP_INSIGHTS_NAME created"

#### Step 7 Create Public IP for Application Gateway ####

az network public-ip create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:PIP_NAME `
  --allocation-method Static `
  --sku Standard `
  --location $env:REGION
Write-Output "Public IP $env:PIP_NAME created"

#### Step 8 Create Application Gateway ####

$env:APPGW_SUBNET_ID = az network vnet subnet show `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --vnet-name $env:VNET_NAME `
  --name snet-appgateway `
  --query "id" -o tsv
Write-Output "App Gateway Subnet ID: $env:APPGW_SUBNET_ID"

az network application-gateway create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:APPGW_NAME `
  --location $env:REGION `
  --sku Standard_v2 `
  --capacity 1 `
  --public-ip-address $env:PIP_NAME `
  --subnet $env:APPGW_SUBNET_ID `
  --frontend-port 80 `
  --http-settings-port 80 `
  --http-settings-protocol Http `
  --routing-rule-type Basic `
  --priority 9
Write-Output "Application Gateway $env:APPGW_NAME created"

# Configure SSL policy
az network application-gateway ssl-policy set `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --gateway-name $env:APPGW_NAME `
  --policy-type Predefined `
  --policy-name AppGwSslPolicy20220101
Write-Output "SSL policy configured on $env:APPGW_NAME"

# Add health probe
az network application-gateway probe create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --gateway-name $env:APPGW_NAME `
  --name http-health-probe `
  --protocol Http `
  --host-name-from-http-settings true `
  --path "/" `
  --interval 30 `
  --timeout 30 `
  --threshold 3
Write-Output "Health probe added to $env:APPGW_NAME"

#### Step 9 Create Azure Container Registry ####

az acr create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:ACR_NAME `
  --sku Standard `
  --admin-enabled false `
  --location $env:REGION
Write-Output "ACR $env:ACR_NAME created"

#### Step 10 Create User Assigned Managed Identity ####

az identity create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:IDENTITY_NAME `
  --location $env:REGION
Write-Output "Managed Identity $env:IDENTITY_NAME created"

#### Step 11 Create AKS Cluster ####

$env:AKS_SUBNET_ID = az network vnet subnet show `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --vnet-name $env:VNET_NAME `
  --name snet-aks `
  --query "id" -o tsv
Write-Output "AKS Subnet ID: $env:AKS_SUBNET_ID"

$env:K8S_VERSION = az aks get-versions `
  --location $env:REGION `
  --query "values[?isDefault==``true``].version | [0]" -o tsv
Write-Output "Kubernetes Version: $env:K8S_VERSION"

az aks create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:AKS_CLUSTER_NAME `
  --location $env:REGION `
  --kubernetes-version $env:K8S_VERSION `
  --node-resource-group "$env:RESOURCE_GROUP_NAME-node-rg" `
  --node-count 3 `
  --nodepool-name systempool `
  --node-vm-size Standard_A2_v2 `
  --os-sku AzureLinux `
  --vnet-subnet-id $env:AKS_SUBNET_ID `
  --network-plugin azure `
  --network-plugin-mode overlay `
  --network-dataplane cilium `
  --network-policy cilium `
  --load-balancer-sku standard `
  --enable-managed-identity `
  --enable-oidc-issuer `
  --enable-workload-identity `
  --enable-addons monitoring,web_application_routing `
  --workspace-resource-id $env:LOG_WORKSPACE_ID `
  --nodepool-labels nodepool=systempool env=aks-mod `
  --generate-ssh-keys
Write-Output "AKS Cluster $env:AKS_CLUSTER_NAME created"

#### Step 12 Get AKS Credentials ####

az aks get-credentials `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:AKS_CLUSTER_NAME `
  --overwrite-existing
Write-Output "Connected to AKS Cluster $env:AKS_CLUSTER_NAME"

#### Step 13 Assign Roles to AKS Identity ####

$env:AKS_IDENTITY_PRINCIPAL_ID = az aks show `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:AKS_CLUSTER_NAME `
  --query "identity.principalId" -o tsv
Write-Output "AKS Identity Principal ID: $env:AKS_IDENTITY_PRINCIPAL_ID"

$env:RESOURCE_GROUP_ID = az group show `
  --name $env:RESOURCE_GROUP_NAME `
  --query "id" -o tsv
Write-Output "Resource Group ID: $env:RESOURCE_GROUP_ID"

$env:SUBSCRIPTION_ID = az account show --query "id" -o tsv
Write-Output "Subscription ID: $env:SUBSCRIPTION_ID"

# Network Contributor on Resource Group
az role assignment create `
  --assignee-object-id $env:AKS_IDENTITY_PRINCIPAL_ID `
  --assignee-principal-type ServicePrincipal `
  --role "Network Contributor" `
  --scope $env:RESOURCE_GROUP_ID
Write-Output "Network Contributor role assigned on resource group"

# Network Contributor on AKS subnet
az role assignment create `
  --assignee-object-id $env:AKS_IDENTITY_PRINCIPAL_ID `
  --assignee-principal-type ServicePrincipal `
  --role "Network Contributor" `
  --scope $env:AKS_SUBNET_ID
Write-Output "Network Contributor role assigned on AKS subnet"

# Contributor on subscription
az role assignment create `
  --assignee-object-id $env:AKS_IDENTITY_PRINCIPAL_ID `
  --assignee-principal-type ServicePrincipal `
  --role "Contributor" `
  --scope "/subscriptions/$env:SUBSCRIPTION_ID"
Write-Output "Contributor role assigned on subscription"

# AcrPull on ACR
$env:ACR_ID = az acr show `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:ACR_NAME `
  --query "id" -o tsv
Write-Output "ACR ID: $env:ACR_ID"

az role assignment create `
  --assignee-object-id $env:AKS_IDENTITY_PRINCIPAL_ID `
  --assignee-principal-type ServicePrincipal `
  --role "AcrPull" `
  --scope $env:ACR_ID
Write-Output "AcrPull role assigned on ACR"

#### Step 14 Create Linux Jumpbox VM ####

$env:VM_SUBNET_ID = az network vnet subnet show `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --vnet-name $env:VNET_NAME `
  --name snet-vm `
  --query "id" -o tsv
Write-Output "VM Subnet ID: $env:VM_SUBNET_ID"

az network nic create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:NIC_NAME `
  --subnet $env:VM_SUBNET_ID `
  --ip-forwarding true `
  --location $env:REGION
Write-Output "NIC $env:NIC_NAME created"

az vm create `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:VM_NAME `
  --location $env:REGION `
  --size Standard_D2ads_v6 `
  --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest `
  --admin-username azureuser `
  --admin-password $env:VM_ADMIN_PASSWORD `
  --nics $env:NIC_NAME `
  --os-disk-size-gb 64 `
  --os-disk-caching ReadOnly `
  --storage-sku StandardSSD_LRS `
  --priority Spot `
  --eviction-policy Delete `
  --public-ip-address "" `
  --authentication-type password
Write-Output "Jumpbox VM $env:VM_NAME created"

#### Step 15 Output Summary ####

$env:APP_GATEWAY_PIP = az network public-ip show `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:PIP_NAME `
  --query "ipAddress" -o tsv
Write-Output "App Gateway Public IP: $env:APP_GATEWAY_PIP"

$env:ACR_LOGIN_SERVER = az acr show `
  --resource-group $env:RESOURCE_GROUP_NAME `
  --name $env:ACR_NAME `
  --query "loginServer" -o tsv
Write-Output "ACR Login Server: $env:ACR_LOGIN_SERVER"

Write-Output "Jumpbox SSH: ssh azureuser@<vm-private-ip> (from within VNet)"
Write-Output "Jumpbox Password: $env:VM_ADMIN_PASSWORD"
Write-Output "Managed Identity Client ID: $env:AKS_IDENTITY_PRINCIPAL_ID"
Write-Output "Setup complete."
