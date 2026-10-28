# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND

# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"

#set name suffix
$env:NAME_SUFFIX = "$RAND"
Write-Output "Name suffix set to: $env:NAME_SUFFIX"

# Create short suffix (first 6 characters) for resource names with length limits
$env:SHORT_SUFFIX = $env:NAME_SUFFIX.Substring(0, [Math]::Min(6, $env:NAME_SUFFIX.Length))

# Set Location
$env:LOCATION = "northeurope"
Write-Output "Location set to: $env:LOCATION"

# Create a resource group name using the random number
$env:APPNET_RG_NAME = "rg-appnet-$RAND"
Write-Output "Resource group name: $env:APPNET_RG_NAME"

$env:APPNET_NAME = "appnet-$RAND"
Write-Output "Application network name: $env:APPNET_NAME"

$env:AKS_RG_NAME = "rg-aks-$RAND"
Write-Output "Resource group name: $env:AKS_RG_NAME"

# Setup AKS Cluster
$env:AKS_CLUSTER_NAME = "aks-cluster$RAND"
Write-Output "AKS cluster name: $env:AKS_CLUSTER_NAME"

# Generate a short random name for user assigned identity (globally unique)
$env:APPNET_MEMBER_NAME = "appnet-member-$RAND"
Write-Output "User assigned identity name: $env:APPNET_MEMBER_NAME"

# Generate a short random name for ACR (globally unique)
$env:ACR_NAME = "appnetacr$($env:SHORT_SUFFIX)"
Write-Output "ACR name: $env:ACR_NAME"

# Generate a short random name for user assigned identity (globally unique)
$env:USER_ASSIGNED_IDENTITY_NAME = "appnet-identity-$RAND"
Write-Output "User assigned identity name: $env:USER_ASSIGNED_IDENTITY_NAME"

# get subscription
$env:SUBSCRIPTION = az account show --query id -o tsv
Write-Output "Current subscription ID: $env:SUBSCRIPTION"

# register preview features
az extension add --name aks-preview
az feature register --name DisableSSHPreview --namespace Microsoft.ContainerService
az feature register --namespace "Microsoft.ContainerService" --name "AdvancedNetworkingFlowLogsPreview"
az feature register --namespace "Microsoft.ContainerService" --name "AdvancedNetworkingL7PolicyPreview"
az feature register --namespace Microsoft.AppLink --name PublicPreview --subscription $env:SUBSCRIPTION
Write-Output "Preview features registered. This may take a few minutes."

# refresh the registration of the microsoft.AppLink 
az provider register --namespace Microsoft.AppLink --subscription $env:SUBSCRIPTION
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.ServiceLinker
az provider register --namespace Microsoft.KubernetesConfiguration
Write-Output "Providers registration initiated."

# install AppNet CLI xtension
az extension add --name appnet-preview
Write-Output "AppNet CLI extension installed."

# CREATE THE AKS RESOURCE GROUP !
az group create --name $env:AKS_RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:AKS_RG_NAME created"

# Get the latest Kubernetes version available in the region
$env:K8S_VERSION=$(az aks get-versions -l $env:LOCATION `
--query "values[?isDefault==``true``].version | [0]" `
-o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"

# create user assighned managed identiy 
az identity create --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:AKS_RG_NAME --location $env:LOCATION
Write-Output "User assigned managed identity $env:USER_ASSIGNED_IDENTITY_NAME created in resource group $env:AKS_RG_NAME"

# store identity details
Write-Output "Waiting for identity propagation..."
Start-Sleep -Seconds 30
$env:USER_ASSIGNED_IDENTITY_ID=$(az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:AKS_RG_NAME --query 'id' -o tsv)
$env:USER_ASSIGNED_IDENTITY_CLIENT_ID=$(az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:AKS_RG_NAME --query 'clientId' -o tsv)
$env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID=$(az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:AKS_RG_NAME --query 'principalId' -o tsv)
Write-Output "User assigned managed identity details stored."

# Get the current user's object ID for Key Vault permissions
$env:USER_OBJECT_ID = az ad signed-in-user show --query "id" -o tsv
Write-Output "User Object ID: $env:USER_OBJECT_ID"

# Get  Azure tenant ID
$env:TENANT_ID = az account show --query "tenantId" -o tsv
Write-Output "Tenant ID: $env:TENANT_ID"

# Create ACR
Write-Output "Creating Azure Container Registry: $env:ACR_NAME"
az acr create `
  --resource-group $env:AKS_RG_NAME `
  --name $env:ACR_NAME `
  --sku Standard `
  --location $env:LOCATION
Write-Output "Azure Container Registry $env:ACR_NAME created successfully."

# Enable system-assigned managed identity on ACR
az acr identity assign `
  --identities "[system]" `
  --name $env:ACR_NAME `
  --resource-group $env:AKS_RG_NAME
Write-Output "System-assigned managed identity enabled on ACR $env:ACR_NAME."

# Capture ACR details
$env:ACR_ID = az acr show `
  --name $env:ACR_NAME `
  --resource-group $env:AKS_RG_NAME `
  --query "id" -o tsv
Write-Output "ACR ID: $env:ACR_ID"
$env:ACR_LOGIN_SERVER = az acr show `
  --name $env:ACR_NAME `
  --resource-group $env:AKS_RG_NAME `
  --query "loginServer" -o tsv
Write-Output "Container Registry: $env:ACR_LOGIN_SERVER"

# Create Log Analytics Workspace
$env:LOG_WORKSPACE_NAME = "mylogs$env:NAME_SUFFIX"
Write-Output "Creating Log Analytics Workspace: $env:LOG_WORKSPACE_NAME"
az monitor log-analytics workspace create `
  --resource-group $env:AKS_RG_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
  --identity-type SystemAssigned `
  --location $env:LOCATION
Write-Output "Log Analytics Workspace $env:LOG_WORKSPACE_NAME created in resource group $env:AKS_RG_NAME"
$env:LOG_WORKSPACE_ID = az monitor log-analytics workspace show `
  --resource-group $env:AKS_RG_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
  --query "id" -o tsv
Write-Output "Log Analytics Workspace ID: $env:LOG_WORKSPACE_ID"

# Create Azure Monitor Workspace (Prometheus)
$env:PROMETHEUS_NAME = "myprometheus$env:NAME_SUFFIX"
Write-Output "Creating Azure Monitor Workspace: $env:PROMETHEUS_NAME"
az monitor account create `
  --name $env:PROMETHEUS_NAME `
  --resource-group $env:AKS_RG_NAME `
  --location $env:LOCATION
$env:METRICS_WORKSPACE_ID = az monitor account show `
  --name $env:PROMETHEUS_NAME `
  --resource-group $env:AKS_RG_NAME `
  --query "id" -o tsv
Write-Output "Azure Monitor Workspace ID: $env:METRICS_WORKSPACE_ID"

# Create Application Insights
$env:APP_INSIGHTS_NAME = "myappinsights$env:NAME_SUFFIX"
Write-Output "Creating Application Insights: $env:APP_INSIGHTS_NAME"
az monitor app-insights component create `
  --app $env:APP_INSIGHTS_NAME `
  --location $env:LOCATION `
  --resource-group $env:AKS_RG_NAME `
  --workspace $env:LOG_WORKSPACE_ID
$env:APP_INSIGHTS_CONNECTION_STRING = az monitor app-insights component show `
  --app $env:APP_INSIGHTS_NAME `
  --resource-group $env:AKS_RG_NAME `
  --query "connectionString" -o tsv
Write-Output "Application Insights Connection String: $env:APP_INSIGHTS_CONNECTION_STRING"

# Create Key Vault with RBAC enabled
$env:KV_NAME = "kv-$(Get-Random -Minimum 1000 -Maximum 9999)"
Write-Output "Creating Key Vault: $env:KV_NAME"
az keyvault create `
  --name $env:KV_NAME `
  --resource-group $env:AKS_RG_NAME `
  --location $env:LOCATION `
  --enable-rbac-authorization true `
  --sku standard
Write-Output "Azure Key Vault $env:KV_NAME created in resource group $env:AKS_RG_NAME"

# Get Key Vault ID
$env:KV_ID = az keyvault show `
  --name $env:KV_NAME `
  --resource-group $env:AKS_RG_NAME `
  --query "id" -o tsv

# Get Key Vault URI
$env:KV_URI = az keyvault show `
  --name $env:KV_NAME `
  --query "properties.vaultUri" -o tsv
Write-Output "Key Vault URI: $env:KV_URI"

# Assign Key Vault Secrets User role to the managed identity
Write-Output "Assigning Key Vault Secrets User role to managed identity..."
az role assignment create `
  --role "Key Vault Secrets User" `
  --assignee $env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID `
  --scope $env:KV_ID

# Assign Key Vault Certificate User role to the managed identity
Write-Output "Assigning Key Vault Certificate User role to managed identity..."
az role assignment create `
  --role "Key Vault Certificate User" `
  --assignee $env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID `
  --scope $env:KV_ID

# Assign Key Vault Administrator role to the current user
Write-Output "Assigning Key Vault Administrator role to current user..."
az role assignment create `
  --role "Key Vault Administrator" `
  --assignee $env:USER_OBJECT_ID `
  --scope $env:KV_ID
  
# create aks cluster with AKS-managed Microsoft Entra integration and OIDC issuer enabled
az aks create `
--resource-group $env:AKS_RG_NAME `
--name $env:AKS_CLUSTER_NAME `
--location $env:LOCATION `
--tier standard `
--kubernetes-version $env:K8S_VERSION `
--load-balancer-sku standard `
--network-plugin azure `
--network-plugin-mode overlay `
--network-dataplane cilium `
--network-policy cilium `
--attach-acr $env:ACR_NAME `
--workspace-resource-id $env:LOG_WORKSPACE_ID `
--azure-monitor-workspace-resource-id $env:METRICS_WORKSPACE_ID `
--enable-workload-identity `
--enable-aad `
--enable-oidc-issuer `
--enable-acns `
--enable-addons monitoring,azure-keyvault-secrets-provider `
--enable-container-network-logs `
--acns-advanced-networkpolicies L7 `
--enable-high-log-scale-mode `
--enable-azure-rbac `
--enable-cluster-autoscaler `
--min-count 1 `
--max-count 3 `
--enable-azure-monitor-metrics `
--ssh-access disabled
Write-Output "AKS Cluster $env:AKS_CLUSTER_NAME created successfully in resource group $env:AKS_RG_NAME with ssh-access disabled, workload identity enabled, and AI toolchain operator dissabled."

# Capture AKS cluster ID
$env:AKS_CLUSTER_ID = az aks show `
  --name $env:AKS_CLUSTER_NAME `
  --resource-group $env:AKS_RG_NAME `
  --query id `
  --output tsv
Write-Output "AKS Cluster ID: $env:AKS_CLUSTER_ID"

# Capture AKS cluster FQDN
$env:AKS_CLUSTER_FQDN = az aks show `
  --name $env:AKS_CLUSTER_NAME `
  --resource-group $env:AKS_RG_NAME `
  --query "fqdn" `
  --output tsv
Write-Output "AKS Cluster FQDN: $env:AKS_CLUSTER_FQDN"

$env:AKS_OIDC_ISSUER = az aks show `
  --name $env:AKS_CLUSTER_NAME `
  --resource-group $env:AKS_RG_NAME `
  --query "oidcIssuerProfile.issuerUrl" -o tsv
Write-Output "AKS OIDC Issuer URL: $env:AKS_OIDC_ISSUER"

# Connect to the cluster
az aks get-credentials --resource-group $env:AKS_RG_NAME --name $env:AKS_CLUSTER_NAME --overwrite-existing --file "$env:AKS_CLUSTER_NAME.config"
$env:KUBECONFIG = "$PWD\$env:AKS_CLUSTER_NAME.config"
Write-Output "Connected to AKS cluster $env:AKS_CLUSTER_NAME."

az role assignment create `
  --assignee $env:USER_OBJECT_ID `
  --role "Azure Kubernetes Service RBAC Cluster Admin" `
  --scope "/subscriptions/$env:SUBSCRIPTION/resourcegroups/$env:AKS_RG_NAME/providers/Microsoft.ContainerService/managedClusters/$env:AKS_CLUSTER_NAME"

# Get the Key Vault addon identity (provisioned during cluster creation)
$env:IDENTITY_CLIENT_ID = az aks show `
  --resource-group $env:AKS_RG_NAME `
  --name $env:AKS_CLUSTER_NAME `
  --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" `
  -o tsv
Write-Output "Identity Client ID: $env:IDENTITY_CLIENT_ID"

# Assign Key Vault Secrets User role to the addon managed identity
az role assignment create `
  --role "Key Vault Secrets User" `
  --assignee $env:IDENTITY_CLIENT_ID `
  --scope $env:KV_ID
Write-Output "Permissions granted to Key Vault addon managed identity"

# CREATE THE App Net RESOURCE GROUP !
az group create --name $env:APPNET_RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:APPNET_RG_NAME created"

# Create an Azure Kubernetes Application Network resource
az appnet create `
--resource-group $env:APPNET_RG_NAME `
--name $env:APPNET_NAME `
--location northeurope `
--identity-type SystemAssigned
Write-Output "Azure Kubernetes Application Network $env:APPNET_NAME created successfully in resource group $env:APPNET_RG_NAME with system assigned identity."

# Join an AKS cluster as a member of Azure Kubernetes Application Network
az appnet member join `
--resource-group $env:APPNET_RG_NAME `
--appnet-name $env:APPNET_NAME `
--member-name $env:APPNET_MEMBER_NAME `
--member-resource-id /subscriptions/$env:SUBSCRIPTION/resourcegroups/$env:AKS_RG_NAME/providers/Microsoft.ContainerService/managedClusters/$env:AKS_CLUSTER_NAME `
--upgrade-mode SelfManaged `
--east-west-gateway External
Write-Output "AKS Cluster $env:AKS_CLUSTER_NAME joined to Azure Kubernetes Application Network $env:APPNET_NAME as member $env:APPNET_MEMBER_NAME with self-managed upgrade mode."

# --upgrade-mode FullyManaged `

# store resource names in .envrc file
$envrcContent = @"
export APPNET_RG_NAME=$env:APPNET_RG_NAME
export LOCATION=$env:LOCATION
export AKS_RG_NAME=$env:AKS_RG_NAME
export APPNET_NAME=$env:APPNET_NAME
export AKS_CLUSTER_NAME=$env:AKS_CLUSTER_NAME
export APPNET_MEMBER_NAME=$env:APPNET_MEMBER_NAME
export ACR_NAME=$env:ACR_NAME
export NAME_SUFFIX=$env:NAME_SUFFIX
export SHORT_SUFFIX=$env:SHORT_SUFFIX
export USER_ASSIGNED_IDENTITY_NAME=$env:USER_ASSIGNED_IDENTITY_NAME
export SUBSCRIPTION=$env:SUBSCRIPTION
export AKS_OIDC_ISSUER=$env:AKS_OIDC_ISSUER
export KV_URI=$env:KV_URI
export APP_INSIGHTS_CONNECTION_STRING=$env:APP_INSIGHTS_CONNECTION_STRING
"@ | Out-File -FilePath ".envrc" -Encoding utf8
Write-Output ".envrc file created with resource names."

# Verify the member is joined successfully
az appnet member show `
--resource-group $env:APPNET_RG_NAME `
--appnet-name $env:APPNET_NAME `
--member-name $env:APPNET_MEMBER_NAME

