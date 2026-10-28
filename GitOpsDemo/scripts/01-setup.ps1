# Fail fast on errors from both PowerShell cmdlets and native commands (az, kubectl, etc.)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$DEMO_ROOT = Split-Path -Parent $PSScriptRoot

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
$env:LOCATION = "swedencentral"
Write-Output "Location set to: $env:LOCATION"

# Create a resource group name using the random number
$env:RG_NAME = "rg-aks-argo-$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# Setup AKS Cluster
$env:AKS_NAME = "argo-aks-cluster$RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"

# Generate a short random name for user assigned identity (globally unique)
$env:USER_ASSIGNED_IDENTITY_NAME = "argo-identity-$RAND"
Write-Output "User assigned identity name: $env:USER_ASSIGNED_IDENTITY_NAME"

# Generate a short random name for ACR (globally unique)
$env:ACR_NAME = "argoacr$env:SHORT_SUFFIX"
Write-Output "ACR name: $env:ACR_NAME"

# Capture subscription ID for subscription-scope role assignments
$env:AZURE_SUBSCRIPTION_ID = az account show --query id -o tsv
Write-Output "Subscription ID: $env:AZURE_SUBSCRIPTION_ID"
$env:AZURE_TENANT_ID = az account show --query tenantId -o tsv
Write-Output "Tenant ID: $env:AZURE_TENANT_ID"

#set name suffix
$env:NAME_SUFFIX = "$RAND"
Write-Output "Name suffix set to: $env:NAME_SUFFIX"

# CREATE THE RESOURCE GROUP FIRST!
az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:RG_NAME created"

# Get the latest Kubernetes version available in the region
$env:K8S_VERSION=$(az aks get-versions -l $env:LOCATION `
--query "values[?isDefault==``true``].version | [0]" `
-o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"

# create user assighned managed identiy 
az identity create --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --location $env:LOCATION
Write-Output "User assigned managed identity $env:USER_ASSIGNED_IDENTITY_NAME created in resource group $env:RG_NAME"

# store identity details
Write-Output "Waiting for identity propagation..."
Start-Sleep -Seconds 30
$env:USER_ASSIGNED_IDENTITY_ID=$(az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'id' -o tsv)
$env:USER_ASSIGNED_IDENTITY_CLIENT_ID=$(az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'clientId' -o tsv)
$env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID=$(az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'principalId' -o tsv)
Write-Output "User assigned managed identity details stored."

# install kubectl loccally
#Write-Output "Installing kubectl locally and the the latest k8s-configuration and k8s-extension CLI extension packages..."
#az aks install-cli
#az extension add -n k8s-configuration
#az extension add -n k8s-extension
#Write-Output "kubectl installed successfully."

# Registration of the following Azure resource providers
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.KubernetesConfiguration
write-Output "Azure resource providers Microsoft.Kubernetes, Microsoft.ContainerService, and Microsoft.KubernetesConfiguration registered successfully."

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
$env:KV_NAME = "kv-$(Get-Random -Minimum 1000 -Maximum 9999)"
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
  --resource-group $env:RG_NAME `
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

# Get current user object ID
$env:USER_OBJECT_ID = az ad signed-in-user show --query id -o tsv
Write-Output "Current user object ID: $env:USER_OBJECT_ID"

# Grant the current principal Contributor on the subscription and
# Managed Identity Operator on the user-assigned managed identity scope.
$subscriptionScope = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID"
$managedIdentityScope = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID/resourceGroups/$env:RG_NAME/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$env:USER_ASSIGNED_IDENTITY_NAME"

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
--generate-ssh-keys
Write-Output "AKS Cluster $env:AKS_NAME created successfully in resource group $env:RG_NAME with workload identity enabled and attached to ACR $env:ACR_NAME."

az k8s-extension create `
--resource-group $env:RG_NAME `
--cluster-name $env:AKS_NAME `
--cluster-type managedClusters `
--name argocd `
--extension-type Microsoft.ArgoCD `
--config "redis-ha.enabled=false" `
--config "configs.params.application\.namespaces=namespace1,namespace2"
write-Output "ArgoCD extension installed on AKS cluster $env:AKS_NAME with ArgoCD Application namespaces set to namespace1 and namespace2."

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

$env:AKS_OIDC_ISSUER = az aks show `
  --name $env:AKS_NAME `
  --resource-group $env:RG_NAME `
  --query "oidcIssuerProfile.issuerUrl" -o tsv
Write-Output "AKS OIDC Issuer URL: $env:AKS_OIDC_ISSUER"

# Create federated identity credentials for workload identities
az identity federated-credential create `
  --name "aks-labs-capz-manager-credential" `
  --identity-name $env:USER_ASSIGNED_IDENTITY_NAME `
  --resource-group $env:RG_NAME `
  --issuer $env:AKS_OIDC_ISSUER `
  --subject "system:serviceaccount:azure-infrastructure-system:capz-manager" `
  --audiences "api://AzureADTokenExchange"
Write-Output "Federated identity credential created: aks-labs-capz-manager-credential"

az identity federated-credential create `
  --name "serviceoperator" `
  --identity-name $env:USER_ASSIGNED_IDENTITY_NAME `
  --resource-group $env:RG_NAME `
  --issuer $env:AKS_OIDC_ISSUER `
  --subject "system:serviceaccount:azure-infrastructure-system:azureserviceoperator-default" `
  --audiences "api://AzureADTokenExchange"
Write-Output "Federated identity credential created: serviceoperator"

# Grant current user AKS RBAC Cluster Admin for kubectl access
az role assignment create `
  --assignee $env:USER_OBJECT_ID `
  --role "Azure Kubernetes Service RBAC Cluster Admin" `
  --scope $env:AKS_CLUSTER_ID
Write-Output "AKS RBAC Cluster Admin assigned. Waiting for propagation..."
Start-Sleep -Seconds 60

# Connect to the cluster
az aks get-credentials --resource-group $env:RG_NAME --name $env:AKS_NAME --overwrite-existing --file "$DEMO_ROOT\$env:AKS_NAME.config"
$env:KUBECONFIG = "$DEMO_ROOT\$env:AKS_NAME.config"
Write-Output "Connected to AKS cluster $env:AKS_NAME."

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
export USER_ASSIGNED_IDENTITY_NAME=$env:USER_ASSIGNED_IDENTITY_NAME
export USER_ASSIGNED_IDENTITY_CLIENT_ID=$env:USER_ASSIGNED_IDENTITY_CLIENT_ID
export AZURE_TENANT_ID=$env:AZURE_TENANT_ID
export ACR_NAME=$env:ACR_NAME
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
"@ | Out-File -FilePath "$DEMO_ROOT\.envrc" -Encoding utf8
Write-Output ".envrc file created with resource names at $DEMO_ROOT\.envrc"
Write-Output "Next step: run .\scripts\02-devsetup.ps1 to create app-project-env repo, render sample manifests, and trigger Argo CD sync from GitHub."
