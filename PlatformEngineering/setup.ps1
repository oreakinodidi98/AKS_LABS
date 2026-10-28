# Set Variables 
###########################################################

# Set it as an environment variable
$env:RAND = Get-Random
# Print the random resource identifier
Write-Output "Random resource identifier will be: $env:RAND"

#set name suffix
$env:NAME_SUFFIX = "$env:RAND"
Write-Output "Name suffix set to: $env:NAME_SUFFIX"

# Create short suffix (first 6 characters) for resource names with length limits
$env:SHORT_SUFFIX = $env:NAME_SUFFIX.Substring(0, [Math]::Min(6, $env:NAME_SUFFIX.Length))
Write-Output "Short name suffix set to: $env:SHORT_SUFFIX"

# Set Location
$env:LOCATION = "swedencentral"
Write-Output "Location set to: $env:LOCATION"

# Create a resource group name using the random number
$env:RG_NAME = "rg-aks-pe-$env:RAND"
Write-Output "Resource group name: $env:RG_NAME"

# Setup AKS Cluster
$env:AKS_NAME = "pe-aks-cluster$env:RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"

# Current user object ID
$env:USER_OBJECT_ID = az ad signed-in-user show --query id -o tsv
Write-Output "Current user object ID: $env:USER_OBJECT_ID"

# Generate a short random name for user assigned identity (globally unique)
$env:CP_USER_ASSIGNED_IDENTITY_NAME = "cp-identity-$env:RAND"
Write-Output "User assigned identity name: $env:CP_USER_ASSIGNED_IDENTITY_NAME"

# Generate a short random name for user assigned identity (globally unique)
$env:KBL_USER_ASSIGNED_IDENTITY_NAME = "kbl-identity-$env:RAND"
Write-Output "User assigned identity name: $env:KBL_USER_ASSIGNED_IDENTITY_NAME"

# Generate a short random name for ACR (globally unique)
$env:ACR_NAME = "acr$env:SHORT_SUFFIX"
Write-Output "ACR name: $env:ACR_NAME"

# Capture subscription ID for subscription-scope role assignments
$env:AZURE_SUBSCRIPTION_ID = az account show --query id -o tsv
Write-Output "Subscription ID: $env:AZURE_SUBSCRIPTION_ID"
$env:AZURE_TENANT_ID = az account show --query tenantId -o tsv
Write-Output "Tenant ID: $env:AZURE_TENANT_ID"

# KV name
$env:KV_NAME = "kv-$(Get-Random -Minimum 1000 -Maximum 9999)"
Write-Output "Key Vault name: $env:KV_NAME"

# CREATE  RESOURCE GROUP 
az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:RG_NAME created"

# Get the latest Kubernetes version available in the region
$env:K8S_VERSION=$(az aks get-versions -l $env:LOCATION `
--query "values[?isDefault==``true``].version | [0]" `
-o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"

# create CP and Kubelet user assigned managed identity 
az identity create --name $env:CP_USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --location $env:LOCATION
Write-Output "User assigned managed identity $env:CP_USER_ASSIGNED_IDENTITY_NAME created in resource group $env:RG_NAME"

az identity create --name $env:KBL_USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --location $env:LOCATION
Write-Output "User assigned managed identity $env:KBL_USER_ASSIGNED_IDENTITY_NAME created in resource group $env:RG_NAME"

# store identity details
Write-Output "Waiting for identity propagation..."
Start-Sleep -Seconds 30
$env:CP_USER_ASSIGNED_IDENTITY_ID=$(az identity show --name $env:CP_USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'id' -o tsv)
$env:CP_USER_ASSIGNED_IDENTITY_CLIENT_ID=$(az identity show --name $env:CP_USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'clientId' -o tsv)
$env:CP_USER_ASSIGNED_IDENTITY_PRINCIPAL_ID=$(az identity show --name $env:CP_USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'principalId' -o tsv)
$env:KBL_USER_ASSIGNED_IDENTITY_ID=$(az identity show --name $env:KBL_USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'id' -o tsv)
$env:KBL_USER_ASSIGNED_IDENTITY_CLIENT_ID=$(az identity show --name $env:KBL_USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'clientId' -o tsv)
$env:KBL_USER_ASSIGNED_IDENTITY_PRINCIPAL_ID=$(az identity show --name $env:KBL_USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'principalId' -o tsv)
Write-Output "User assigned managed identity details stored."

# Create ACR
Write-Output "Creating Azure Container Registry: $env:ACR_NAME"
az acr create `
  --resource-group $env:RG_NAME `
  --name $env:ACR_NAME `
  --sku Standard `
  --location $env:LOCATION
# Enable system-assigned managed identity on ACR
az acr identity assign `
  --identities "[system]" `
  --name $env:ACR_NAME `
  --resource-group $env:RG_NAME
# Capture ACR details
$env:ACR_ID = az acr show `
  --name $env:ACR_NAME `
  --resource-group $env:RG_NAME `
  --query "id" -o tsv
Write-Output "ACR ID: $env:ACR_ID"
$env:ACR_LOGIN_SERVER = az acr show `
  --name $env:ACR_NAME `
  --resource-group $env:RG_NAME `
  --query "loginServer" -o tsv
Write-Output "Container Registry: $env:ACR_LOGIN_SERVER"

# Create Log Analytics Workspace
$env:LOG_WORKSPACE_NAME = "mylogs$env:NAME_SUFFIX"
Write-Output "Creating Log Analytics Workspace: $env:LOG_WORKSPACE_NAME"
az monitor log-analytics workspace create `
  --resource-group $env:RG_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
  --identity-type SystemAssigned `
  --location $env:LOCATION
Write-Output "Log Analytics Workspace $env:LOG_WORKSPACE_NAME created in resource group $env:RG_NAME"
$env:LOG_WORKSPACE_ID = az monitor log-analytics workspace show `
  --resource-group $env:RG_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
  --query "id" -o tsv
Write-Output "Log Analytics Workspace ID: $env:LOG_WORKSPACE_ID"

# Create Azure Monitor Workspace (Prometheus)
$env:PROMETHEUS_NAME = "myprometheus$env:NAME_SUFFIX"
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

# Create Application Insights
$env:APP_INSIGHTS_NAME = "myappinsights$env:NAME_SUFFIX"
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

# Create Key Vault with RBAC enabled
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
  --resource-group $env:RG_NAME `
  --query "id" -o tsv
Write-Output "Key Vault ID: $env:KV_ID"
# Get Key Vault URI
$env:KV_URI = az keyvault show `
  --name $env:KV_NAME `
  --query "properties.vaultUri" -o tsv
Write-Output "Key Vault URI: $env:KV_URI"

# Grant the current principal Contributor on the subscription and
# Managed Identity Operator on the user-assigned managed identity scope.
$subscriptionScope = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID"
$managedIdentityScope = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID/resourceGroups/$env:RG_NAME/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$env:KBL_USER_ASSIGNED_IDENTITY_NAME"

az role assignment create `
  --assignee $env:USER_OBJECT_ID `
  --role "Contributor" `
  --scope $subscriptionScope
Write-Output "Contributor role assigned at subscription scope."

az role assignment create `
  --assignee $env:USER_OBJECT_ID `
  --role "Managed Identity Operator" `
  --scope $managedIdentityScope
Write-Output "Managed Identity Operator role assigned on user-assigned identity scope."

# Assign Key Vault Secrets User role to the managed identity
Write-Output "Assigning Key Vault Secrets User role to managed identity..."
az role assignment create `
  --role "Key Vault Secrets User" `
  --assignee $env:KBL_USER_ASSIGNED_IDENTITY_PRINCIPAL_ID `
  --scope $env:KV_ID
# Assign Key Vault Certificate User role to the managed identity
Write-Output "Assigning Key Vault Certificate User role to managed identity..."
az role assignment create `
  --role "Key Vault Certificate User" `
  --assignee $env:KBL_USER_ASSIGNED_IDENTITY_PRINCIPAL_ID `
  --scope $env:KV_ID
# Assign Key Vault Administrator role to the current user
Write-Output "Assigning Key Vault Administrator role to current user..."
az role assignment create `
  --role "Key Vault Administrator" `
  --assignee $env:USER_OBJECT_ID `
  --scope $env:KV_ID

# create aks cluster
Write-Output "Creating AKS Cluster: $env:AKS_NAME with  OIDC issuer and workload identity enabled"
az aks create `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--location $env:LOCATION `
--kubernetes-version $env:K8S_VERSION `
--attach-acr $env:ACR_NAME `
--node-count 4 `
--node-vm-size Standard_D4s_v5 `
--load-balancer-sku standard `
--network-plugin azure `
--network-plugin-mode overlay `
--network-dataplane cilium `
--network-policy cilium `
--workspace-resource-id $env:LOG_WORKSPACE_ID `
--azure-monitor-workspace-resource-id $env:METRICS_WORKSPACE_ID `
--enable-managed-identity `
--enable-workload-identity `
--enable-oidc-issuer `
--enable-acns `
--enable-addons monitoring,azure-keyvault-secrets-provider `
--enable-container-network-logs `
--acns-advanced-networkpolicies L7 `
--enable-high-log-scale-mode `
--enable-cluster-autoscaler `
--min-count 1 `
--max-count 4 `
--enable-azure-monitor-metrics `
--generate-ssh-keys `
--assign-identity $env:CP_USER_ASSIGNED_IDENTITY_ID `
--assign-kubelet-identity $env:KBL_USER_ASSIGNED_IDENTITY_ID
Write-Output "AKS Cluster $env:AKS_NAME created successfully in resource group $env:RG_NAME with workload identity enabled and attached to ACR $env:ACR_NAME."

# Capture AKS cluster ID
$env:AKS_CLUSTER_ID = az aks show `
  --name $env:AKS_NAME `
  --resource-group $env:RG_NAME `
  --query id `
  --output tsv
Write-Output "AKS Cluster ID: $env:AKS_CLUSTER_ID"

# Capture AKS cluster FQDN
$env:AKS_CLUSTER_FQDN = az aks show `
  --name $env:AKS_NAME `
  --resource-group $env:RG_NAME `
  --query "fqdn" `
  --output tsv
Write-Output "AKS Cluster FQDN: $env:AKS_CLUSTER_FQDN"

# Capture AKS OIDC issuer URL
$env:AKS_OIDC_ISSUER = az aks show `
  --name $env:AKS_NAME `
  --resource-group $env:RG_NAME `
  --query "oidcIssuerProfile.issuerUrl" -o tsv
Write-Output "AKS OIDC Issuer URL: $env:AKS_OIDC_ISSUER"

# set permissions for kubectl 
az role assignment create `
--assignee-object-id $env:KBL_USER_ASSIGNED_IDENTITY_PRINCIPAL_ID `
--assignee-principal-type ServicePrincipal `
--role "Owner" `
--scope $subscriptionScope
write-Output "Owner role assigned to user-assigned identity for AKS cluster administration. here we are using a very coarse, high priviliged role, this is NOT RECOMMENDED"


# Grant current user AKS RBAC Cluster Admin for kubectl access
az role assignment create `
  --assignee $env:USER_OBJECT_ID `
  --role "Azure Kubernetes Service RBAC Cluster Admin" `
  --scope $env:AKS_CLUSTER_ID
Write-Output "AKS RBAC Cluster Admin assigned. Waiting for propagation..."
Start-Sleep -Seconds 60

# Connect to the cluster
az aks get-credentials --resource-group $env:RG_NAME --name $env:AKS_NAME --overwrite-existing --file "$env:AKS_NAME.config"
$env:KUBECONFIG = "$PWD\$env:AKS_NAME.config"
Write-Output "Connected to AKS cluster $env:AKS_NAME."

# Confirm the kubecontext points to the new AKS cluster before continuing
Write-Output "Validating kubecontext..."
kubectl config current-context
kubectl cluster-info

# Get the Key Vault addon identity (provisioned during cluster creation)
$env:IDENTITY_CLIENT_ID = az aks show `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" `
  -o tsv
Write-Output "Identity Client ID: $env:IDENTITY_CLIENT_ID"

# Assign Key Vault Secrets User role to the addon managed identity
az role assignment create `
  --role "Key Vault Secrets User" `
  --assignee $env:IDENTITY_CLIENT_ID `
  --scope $env:KV_ID
Write-Output "Permissions granted to Key Vault addon managed identity"

# store resource names in .envrc file
@"
export RG_NAME=$env:RG_NAME
export LOCATION=$env:LOCATION
export AKS_NAME=$env:AKS_NAME
export CP_USER_ASSIGNED_IDENTITY_NAME=$env:CP_USER_ASSIGNED_IDENTITY_NAME
export CP_USER_ASSIGNED_IDENTITY_CLIENT_ID=$env:CP_USER_ASSIGNED_IDENTITY_CLIENT_ID
export KBL_USER_ASSIGNED_IDENTITY_NAME=$env:KBL_USER_ASSIGNED_IDENTITY_NAME
export KBL_USER_ASSIGNED_IDENTITY_CLIENT_ID=$env:KBL_USER_ASSIGNED_IDENTITY_CLIENT_ID
export AZURE_TENANT_ID=$env:AZURE_TENANT_ID
export ACR_NAME=$env:ACR_NAME
export ACR_ID=$env:ACR_ID
export ACR_LOGIN_SERVER=$env:ACR_LOGIN_SERVER
export NAME_SUFFIX=$env:NAME_SUFFIX
export SHORT_SUFFIX=$env:SHORT_SUFFIX
export K8S_VERSION=$env:K8S_VERSION
export AKS_CLUSTER_ID=$env:AKS_CLUSTER_ID
export AKS_CLUSTER_FQDN=$env:AKS_CLUSTER_FQDN
export AKS_OIDC_ISSUER=$env:AKS_OIDC_ISSUER
export KV_NAME=$env:KV_NAME
export KV_URI=$env:KV_URI
export APP_INSIGHTS_CONNECTION_STRING=$env:APP_INSIGHTS_CONNECTION_STRING
"@ | Out-File -FilePath ".envrc" -Encoding utf8
Write-Output ".envrc file created with resource names."