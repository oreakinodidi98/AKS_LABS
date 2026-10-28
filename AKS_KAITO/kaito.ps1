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
$env:RG_NAME = "rg-aks-kaito-$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# Setup AKS Cluster
$env:AKS_NAME = "kaito-aks-cluster$RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"

# Generate a short random name for user assigned identity (globally unique)
$env:USER_ASSIGNED_IDENTITY_NAME = "kaito-identity-$RAND"
Write-Output "User assigned identity name: $env:USER_ASSIGNED_IDENTITY_NAME"

# Generate a short random name for ACR (globally unique)
$env:ACR_NAME = "kaitoacr$SHORT_SUFFIX"
Write-Output "ACR name: $env:ACR_NAME"

#set name suffix
$env:NAME_SUFFIX = "$RAND"
Write-Output "Name suffix set to: $env:NAME_SUFFIX"

# store resource names in .envrc file
$envrcContent = @"
export RG_NAME=$env:RG_NAME
export LOCATION=$env:LOCATION
export AKS_NAME=$env:AKS_NAME
export USER_ASSIGNED_IDENTITY_NAME=$env:USER_ASSIGNED_IDENTITY_NAME
export ACR_NAME=$env:ACR_NAME
export NAME_SUFFIX=$env:NAME_SUFFIX
export SHORT_SUFFIX=$env:SHORT_SUFFIX
"@ | Out-File -FilePath ".envrc" -Encoding utf8
Write-Output ".envrc file created with resource names."


# register preview features
az extension add --name aks-preview
az feature register --name DisableSSHPreview --namespace Microsoft.ContainerService
az feature register --namespace "Microsoft.ContainerService" --name "AdvancedNetworkingFlowLogsPreview"
az feature register --namespace "Microsoft.ContainerService" --name "AdvancedNetworkingL7PolicyPreview"
Write-Output "Preview features registered. This may take a few minutes."
# register following providers
az provider register --namespace Microsoft.Quota
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.PolicyInsights
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.ServiceLinker
az provider register --namespace Microsoft.KubernetesConfiguration

Write-Output "Providers registration initiated."

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


# create aks cluster
az aks create `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--location $env:LOCATION `
--tier standard `
--kubernetes-version $env:K8S_VERSION `
--load-balancer-sku standard `
--network-plugin azure `
--network-plugin-mode overlay `
--network-dataplane cilium `
--network-policy cilium `
--enable-workload-identity `
--enable-oidc-issuer `
--enable-acns `
--enable-addons monitoring,azure-keyvault-secrets-provider `
--enable-container-network-logs `
--acns-advanced-networkpolicies L7 `
--enable-high-log-scale-mode `
--enable-cluster-autoscaler `
--min-count 1 `
--max-count 3 `
--ssh-access disabled
Write-Output "AKS Cluster $env:AKS_NAME created successfully in resource group $env:RG_NAME with ssh-access disabled, workload identity enabled, and AI toolchain operator dissabled."

# create gpu node pool with spot instances
az aks nodepool add --name nc24adsa100g `
--resource-group $env:RG_NAME `
--cluster-name $env:AKS_NAME `
--node-vm-size Standard_NC24ads_A100_v4 `
--tags EnableManagedGPUExperience=true `
--node-count 1 `
--priority Spot `
--eviction-policy Delete `
--enable-cluster-autoscaler `
--ssh-access disabled `
--min-count 1 `
--max-count 3
Write-Output "Spot GPU node pools created successfully in AKS cluster $env:AKS_NAME."


# create normal gpu node pool
az aks nodepool add --name nc24adsa100g2 `
--resource-group $env:RG_NAME `
--cluster-name $env:AKS_NAME `
--node-vm-size Standard_NC24ads_A100_v4 `
--tags EnableManagedGPUExperience=true `
--node-count 1 `
--priority Regular `
--enable-cluster-autoscaler `
--ssh-access disabled `
--min-count 1 `
--max-count 3
Write-Output "GPU node pools created successfully in AKS cluster $env:AKS_NAME."

$env:AKS_OIDC_ISSUER = az aks show `
  --name $env:AKS_NAME `
  --resource-group $env:RG_NAME `
  --query "oidcIssuerProfile.issuerUrl" -o tsv
Write-Output "AKS OIDC Issuer URL: $env:AKS_OIDC_ISSUER"

# create federated identity credential for the managed identity 
az identity federated-credential create `
  --name "federated-credential-$env:AKS_NAME" `
  --identity-name $env:USER_ASSIGNED_IDENTITY_NAME `
  --resource-group $env:RG_NAME `
  --issuer $env:AKS_OIDC_ISSUER `
  --subject "system:serviceaccount:default:aks-mcp" `
  --audiences "api://AzureADTokenExchange" 

# create Contributor role for Managed Identity at resource group scope
az role assignment create `
  --assignee $env:USER_ASSIGNED_IDENTITY_CLIENT_ID `
  --role "Contributor" `
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$env:RG_NAME"
Write-Output "Contributor role assigned to user assigned managed identity $env:USER_ASSIGNED_IDENTITY_NAME at resource group scope."

# Grant current user AKS RBAC Cluster Admin for kubectl access
$CURRENT_USER_ID = az ad signed-in-user show --query id -o tsv
$AKS_ID = az aks show --resource-group $env:RG_NAME --name $env:AKS_NAME --query id -o tsv
az role assignment create `
  --assignee $CURRENT_USER_ID `
  --role "Azure Kubernetes Service RBAC Cluster Admin" `
  --scope $AKS_ID
Write-Output "AKS RBAC Cluster Admin assigned. Waiting for propagation..."
Start-Sleep -Seconds 60

# Connect to the cluster
az aks get-credentials --resource-group $env:RG_NAME --name $env:AKS_NAME --overwrite-existing --file "$env:AKS_NAME.config"
$env:KUBECONFIG = "$PWD\$env:AKS_NAME.config"
Write-Output "Connected to AKS cluster $env:AKS_NAME."

# install KAITO via HELM
helm repo add kaito https://kaito-project.github.io/kaito/charts/kaito
helm repo update

helm upgrade --install kaito-workspace kaito/workspace `
  --namespace kaito-workspace `
  --create-namespace `
  --set clusterName=$env:AKS_NAME `
  --set defaultNodeImageFamily="ubuntu" `
  --set featureGates.gatewayAPIInferenceExtension=true `
  --set featureGates.disableNodeAutoProvisioning=true `
  --set gpu-feature-discovery.nfd.enabled=true `
  --set gpu-feature-discovery.gfd.enabled=true `
  --set nvidiaDevicePlugin.enabled=true