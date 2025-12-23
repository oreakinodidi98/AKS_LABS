# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND

# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"

# Set Location
$env:LOCATION = "uksouth"
Write-Output "Location set to: $env:LOCATION"

# Create a resource group name using the random number
$env:RG_NAME = "myresourcegroup$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# CREATE RESOURCE GROUP !
az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:RG_NAME created"

# register preview features
az extension add --name aks-preview
az feature register --namespace "Microsoft.ContainerService" --name "AdvancedNetworkingFlowLogsPreview"
az feature register --namespace "Microsoft.ContainerService" --name "AdvancedNetworkingL7PolicyPreview"
Write-Output "Preview features registered. This may take a few minutes."

# Get the current user's object ID for Key Vault permissions
$env:USER_OBJECT_ID = az ad signed-in-user show --query "id" -o tsv
Write-Output "User Object ID: $env:USER_OBJECT_ID"

# Generate unique names using a hash
$uniqueString = (Get-Random -Minimum 1000 -Maximum 9999)


# # Create User Assigned Managed Identity
# $env:IDENTITY_NAME = "myidentity$uniqueString"
# Write-Output "Creating Managed Identity: $env:IDENTITY_NAME"
# az identity create `
#   --name $env:IDENTITY_NAME `
#   --resource-group $env:RG_NAME `
#   --location $env:LOCATION
# $env:IDENTITY_PRINCIPAL_ID = az identity show `
#   --name $env:IDENTITY_NAME `
#   --resource-group $env:RG_NAME `
#   --query "principalId" -o tsv
# $env:IDENTITY_CLIENT_ID_USER = az identity show `
#   --name $env:IDENTITY_NAME `
#   --resource-group $env:RG_NAME `
#   --query "clientId" -o tsv
# Write-Output "Managed Identity Principal ID: $env:IDENTITY_PRINCIPAL_ID"

# Wait for identity propagation
Write-Output "Waiting for identity propagation..."
Start-Sleep -Seconds 30

# create managed identity for ACR pull
$env:AKS_IDENTITY="myaksidentity$uniqueString"
Write-Output "Creating Managed Identity for ACR pull: $env:AKS_IDENTITY"
$env:KUBELET_IDENTITY="mykubeletidentity$uniqueString"
#create user managed identity for kubelet
$env:AKS_IDENTITY_ID=$(az identity create --name $env:AKS_IDENTITY --resource-group $env:RG_NAME --query id -o tsv)
Write-Output "Managed Identity for AKS created: $env:AKS_IDENTITY_ID"
$env:KUBELET_IDENTITY_ID=$(az identity create --name $env:KUBELET_IDENTITY --resource-group $env:RG_NAME --query id -o tsv)
Write-Output "Managed Identity for Kubelet created: $env:KUBELET_IDENTITY_ID"

# Create Log Analytics Workspace
$env:LOG_WORKSPACE_NAME = "mylogs$uniqueString"
Write-Output "Creating Log Analytics Workspace: $env:LOG_WORKSPACE_NAME"
az monitor log-analytics workspace create `
  --resource-group $env:RG_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
  --location $env:LOCATION
$env:LOG_WORKSPACE_ID = az monitor log-analytics workspace show `
  --resource-group $env:RG_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
  --query "id" -o tsv
Write-Output "Log Analytics Workspace ID: $env:LOG_WORKSPACE_ID"

# Create Azure Monitor Workspace (Prometheus)
$env:PROMETHEUS_NAME = "myprometheus$uniqueString"
Write-Output "Creating Azure Monitor Workspace: $env:PROMETHEUS_NAME"
az monitor account create `
  --name $env:PROMETHEUS_NAME `
  --resource-group $env:RG_NAME `
  --location $env:LOCATION
$env:METRICS_WORKSPACE_ID = az monitor account show `
  --name $env:PROMETHEUS_NAME `
  --resource-group $env:RG_NAME `
  --query "id" -o tsv
Write-Output "Azure Monitor Workspace ID: $env:METRICS_WORKSPACE_ID"

# Create Container Registry
$env:ACR_NAME = "myregistry$uniqueString"
Write-Output "Creating Azure Container Registry: $env:ACR_NAME"
az acr create `
  --resource-group $env:RG_NAME `
  --name $env:ACR_NAME `
  --sku Standard `
  --location $env:LOCATION `
  --workspace $env:LOG_WORKSPACE_ID `
  --admin-enabled false
$env:ACR_ID = az acr show `
  --name $env:ACR_NAME `
  --resource-group $env:RG_NAME `
  --query "id" -o tsv
$env:ACR_LOGIN_SERVER = az acr show `
  --name $env:ACR_NAME `
  --resource-group $env:RG_NAME `
  --query "loginServer" -o tsv
Write-Output "Container Registry: $env:ACR_LOGIN_SERVER"

# Create Application Insights
$env:APP_INSIGHTS_NAME = "myappinsights$uniqueString"
Write-Output "Creating Application Insights: $env:APP_INSIGHTS_NAME"
az monitor app-insights component create `
  --app $env:APP_INSIGHTS_NAME `
  --location $env:LOCATION `
  --resource-group $env:RG_NAME `
  --workspace $env:LOG_WORKSPACE_ID
$env:APP_INSIGHTS_CONNECTION_STRING = az monitor app-insights component show `
  --app $env:APP_INSIGHTS_NAME `
  --resource-group $env:RG_NAME `
  --query "connectionString" -o tsv
Write-Output "Application Insights Connection String: $env:APP_INSIGHTS_CONNECTION_STRING"

# Assign Key Vault Secrets User role to the managed identity
Write-Output "Assigning Key Vault Secrets User role to managed identity..."
az role assignment create `
  --role "Key Vault Secrets User" `
  --assignee $env:IDENTITY_PRINCIPAL_ID `
  --scope $env:KV_ID

# Assign Key Vault Certificate User role to the managed identity
Write-Output "Assigning Key Vault Certificate User role to managed identity..."
az role assignment create `
  --role "Key Vault Certificate User" `
  --assignee $env:IDENTITY_PRINCIPAL_ID `
  --scope $env:KV_ID

# Assign Key Vault Administrator role to the current user
Write-Output "Assigning Key Vault Administrator role to current user..."
az role assignment create `
  --role "Key Vault Administrator" `
  --assignee $env:USER_OBJECT_ID `
  --scope $env:KV_ID

# Setup AKS Cluster
$env:AKS_NAME = "myakscluster$RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"

# Get the latest Kubernetes version available in the region
#env:K8S_VERSION=$(az aks get-versions -l $env:LOCATION --query "orchestrators[?default==\`$true\`].orchestratorVersion | [0]" -o tsv)

$env:K8S_VERSION=$(az aks get-versions -l $env:LOCATION `
--query "values[?isDefault==``true``].version | [0]" `
-o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"

# create aks cluster
az aks create `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--location $env:LOCATION `
--tier standard `
--kubernetes-version $env:K8S_VERSION `
--os-sku AzureLinux `
--nodepool-name systempool `
--node-count 3 `
--load-balancer-sku standard `
--network-plugin azure `
--network-plugin-mode overlay `
--network-dataplane cilium `
--network-policy cilium `
--enable-managed-identity `
--assign-identity $env:AKS_IDENTITY_ID `
--assign-kubelet-identity $env:KUBELET_IDENTITY_ID `
--attach-acr $env:ACR_ID `
--pod-cidr 192.168.0.0/16 `
--enable-workload-identity `
--enable-oidc-issuer `
--enable-acns `
--enable-ahub `
--enable-addons monitoring `
--workspace-resource-id $env:LOG_WORKSPACE_ID `
--enable-container-network-logs `
--acns-advanced-networkpolicies L7 `
--enable-high-log-scale-mode `
--generate-ssh-keys
Write-Output "AKS Cluster $env:AKS_NAME created successfully in resource group $env:RG_NAME"

# Connect to the cluster
az aks get-credentials `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--overwrite-existing
Write-Output "Connected to AKS Cluster $env:AKS_NAME"

# add linux user nodepool
az aks nodepool add `
--resource-group $env:RG_NAME `
--cluster-name $env:AKS_NAME `
--mode User `
--os-type Linux `
--name linuxuserpool `
--enable-cluster-autoscaler `
--min-count 1 `
--max-count 3 `
--node-count 1
Write-Output "Linux user nodepool added to AKS Cluster $env:AKS_NAME"

# add windows user nodepool
az aks nodepool add `
--resource-group $env:RG_NAME `
--cluster-name $env:AKS_NAME `
--mode User `
--os-type Windows `
--name windowsuserpool `
--zones 1 2 3 `
--node-count 1
Write-Output "Windows user nodepool added to AKS Cluster $env:AKS_NAME"

# taint the system nodepool
az aks nodepool update `
--resource-group $env:RG_NAME `
--cluster-name $env:AKS_NAME `
--name systempool `
--node-taints CriticalAddonsOnly=true:NoSchedule
Write-Output "System nodepool tainted in AKS Cluster $env:AKS_NAME"

# Enable Key Vault integration in AKS
az aks enable-addons `
  --addons azure-keyvault-secrets-provider `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME
Write-Output "Azure Key Vault Secrets Provider addon enabled in AKS Cluster $env:AKS_NAME"

# Get the Key Vault addon identity
$env:KV_IDENTITY_CLIENT_ID = az aks show `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" `
  -o tsv
Write-Output "Identity Client ID: $env:KV_IDENTITY_CLIENT_ID"


# Create Key Vault with RBAC enabled
$env:KV_NAME = "ft-kv-$(Get-Random -Minimum 1000 -Maximum 9999)"
Write-Output "Creating Key Vault: $env:KV_NAME"
az keyvault create `
  --name $env:KV_NAME `
  --resource-group $env:RG_NAME `
  --location $env:LOCATION `
  --enable-rbac-authorization true `
  --sku standard
Write-Output "Azure Key Vault $env:KV_NAME created in resource group $env:RG_NAME"

# Get Key Vault ID
$env:KV_ID = az keyvault show `
  --name $env:KV_NAME `
  --query "id" -o tsv

# Get Key Vault URI
$env:KV_URI = az keyvault show `
  --name $env:KV_NAME `
  --query "properties.vaultUri" -o tsv
Write-Output "Key Vault URI: $env:KV_URI"

# Get Key Vault scope
$env:KV_SCOPE = az keyvault show `
  --name $env:KV_NAME `
  --query "id" `
  -o tsv
# Get current user object ID
$CURRENT_USER_ID=(az ad signed-in-user show --query "{id:id}" -o tsv)
# Assighn myself keyvault secret offier
az role assignment create `
  --role "Key Vault Secrets Officer" `
  --assignee-object-id $CURRENT_USER_ID `
  --scope $env:KV_ID
# Assign Key Vault Secrets User role to the managed identity
az role assignment create `
  --role "Key Vault Secrets User" `
  --assignee $env:KV_IDENTITY_CLIENT_ID `
  --scope $env:KV_SCOPE
Write-Output "✅ Permissions granted to managed identity"

# Get your Azure tenant ID
$env:TENANT_ID = az account show --query "tenantId" -o tsv
Write-Output "Tenant ID: $env:TENANT_ID"

Write-Output "`n========================================="
Write-Output "Deployment Complete!"
Write-Output "=========================================`n"
Write-Output "Resource Group: $env:RG_NAME"
Write-Output "AKS Cluster: $env:AKS_NAME"
Write-Output "Log Analytics Workspace: $env:LOG_WORKSPACE_NAME"
Write-Output "Azure Monitor Workspace: $env:PROMETHEUS_NAME"
Write-Output "Container Registry: $env:ACR_LOGIN_SERVER"
Write-Output "Key Vault: $env:KV_NAME"
Write-Output "Key Vault URI: $env:KV_URI"
Write-Output "Application Insights: $env:APP_INSIGHTS_NAME"
Write-Output "Managed Identity: $env:IDENTITY_NAME"
Write-Output "`n=========================================`n"