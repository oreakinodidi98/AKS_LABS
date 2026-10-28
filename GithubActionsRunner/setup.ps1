# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND

# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"

# Set Location
$env:LOCATION = "swedencentral"
Write-Output "Location set to: $env:LOCATION"

# Create a resource group name using the random number
$env:RG_NAME = "rg-arc$RAND"
Write-Output "Resource group name: $env:RG_NAME"

#set name suffix
$env:NAME_SUFFIX = "$RAND"
Write-Output "Name suffix set to: $env:NAME_SUFFIX"

# Create short suffix (first 6 characters) for resource names with length limits
$SHORT_SUFFIX = $env:NAME_SUFFIX.Substring(0, [Math]::Min(6, $env:NAME_SUFFIX.Length))

# Validate the active Azure CLI account before creating any resources.
$azureAccountJson = az account show --output json
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($azureAccountJson)) {
  throw "Azure CLI is not authenticated. Run 'az login' and rerun this script."
}
$azureAccount = $azureAccountJson | ConvertFrom-Json
$env:AZURE_SUBSCRIPTION_ID = $azureAccount.id
Write-Output "Subscription ID: $env:AZURE_SUBSCRIPTION_ID"
$env:AZURE_TENANT_ID = $azureAccount.tenantId
Write-Output "Tenant ID: $env:AZURE_TENANT_ID"
$env:USER_PRINCIPAL_NAME = $azureAccount.user.name
if ($azureAccount.user.type -ne "user" -or [string]::IsNullOrWhiteSpace($env:USER_PRINCIPAL_NAME)) {
  throw "This setup requires an interactive Azure user account to configure the PostgreSQL Microsoft Entra administrator."
}
Write-Output "User Principal Name: $env:USER_PRINCIPAL_NAME"

$env:USER_OBJECT_ID = az ad signed-in-user show --query id --output tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($env:USER_OBJECT_ID)) {
  throw "Microsoft Graph authentication failed. Run 'az logout', 'az account clear', and then 'az login --tenant $env:AZURE_TENANT_ID --use-device-code' before rerunning this script."
}
Write-Output "User Object ID: $env:USER_OBJECT_ID"
$subscriptionScope = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID"

# Setup AKS Cluster
$env:AKS_NAME = "aks-arc-$RAND"
$env:ACR_NAME = "acrarc$SHORT_SUFFIX"
Write-Output "AKS cluster name: $env:AKS_NAME"

$env:GITHUB_OWNER = "oreakinodidi98"
$env:GITHUB_REPOSITORY = "oreakinodidi98/AKS_AppMod_Demos"
$env:GITHUB_CONFIG_URL = "https://github.com/$env:GITHUB_REPOSITORY"

$env:RUNNER_SET_NAME = "arc-auto-runners"
$env:ARC_SYSTEMS_NAMESPACE = "arc-systems"
$env:ARC_RUNNERS_NAMESPACE = "arc-runners"
$secureToken = Read-Host "GitHub token" -AsSecureString
$tokenPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
try {
  $env:GITHUB_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($tokenPointer)
}
finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPointer)
}

# Create target git repository
gh repo create $env:GITHUB_REPOSITORY --public --clone
cd $env:GITHUB_REPOSITORY
$env:GITHUB_REPOSITORY_PATHBRANCH = git branch --show-current

# CREATE THE RESOURCE GROUP FIRST!
az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:RG_NAME created"

# Get the latest Kubernetes version available in the region
$env:K8S_VERSION=$(az aks get-versions -l $env:LOCATION `
--query "values[?isDefault==``true``].version | [0]" `
-o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"

$env:USER_PRINCIPAL_NAME = az account show --query user.name -o tsv
$env:USER_OBJECT_ID = az ad signed-in-user show --query id -o tsv
Write-Output "UPN: $env:USER_PRINCIPAL_NAME"
Write-Output "Object ID: $env:USER_OBJECT_ID"

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
  --query "id" -o tsv
# Get Key Vault URI
$env:KV_URI = az keyvault show `
  --name $env:KV_NAME `
  --query "properties.vaultUri" -o tsv
Write-Output "Key Vault URI: $env:KV_URI"
# Assign Key Vault Administrator role to the current user
Write-Output "Assigning Key Vault Administrator role to current user..."
az role assignment create `
  --role "Key Vault Administrator" `
  --assignee $env:USER_OBJECT_ID `
  --scope $env:KV_ID
Write-Output "Key Vault roles assigned successfully."

# create aks cluster
az aks create `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--location $env:LOCATION `
--kubernetes-version $env:K8S_VERSION `
--sku automatic `
--enable-hosted-system `
--enable-managed-identity `
--enable-workload-identity `
--enable-oidc-issuer `
--enable-gateway-api `
--enable-acns `
--no-ssh-key
Write-Output "AKS Cluster $env:AKS_NAME created successfully in resource group $env:RG_NAME"

# Get the AKS cluster's resource ID
$env:AKS_ID = $(az aks show `
    --name $env:AKS_NAME `
    --resource-group $env:RG_NAME `
    --query id `
    --output tsv)
Write-Output "AKS Cluster Resource ID: $env:AKS_ID"

# Assign signed-in identity a scoped AKS RBAC role
az role assignment create `
  --assignee $env:USER_OBJECT_ID `
  --role "Azure Kubernetes Service RBAC Cluster Admin" `
  --scope $env:AKS_ID
Write-Output "Scoped AKS RBAC role assigned to the current user."

# Retrieve the object ID of the AKS cluster's kubelet identity
$env:KUBELET_OBJECT_ID=$(az aks show `
    --name $env:AKS_NAME `
    --resource-group $env:RG_NAME `
    --query identityProfile.kubeletidentity.objectId `
    --output tsv)
write-Output "KUBELET_OBJECT_ID: $env:KUBELET_OBJECT_ID"

# Exec credential flow
az aks get-credentials `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --format exec `
  --overwrite-existing
Write-Output "AKS credentials retrieved successfully."

# Create Container Registry
Write-Output "Creating Azure Container Registry: $env:ACR_NAME"
az acr create `
  --resource-group $env:RG_NAME `
  --name $env:ACR_NAME `
  --sku Standard `
  --location $env:LOCATION `
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

# Allow GitHub Actions to run server-side ACR quick builds (az acr build).
az role assignment create `
  --assignee-object-id $env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID `
  --assignee-principal-type ServicePrincipal `
  --role "Container Registry Tasks Contributor" `
  --scope $env:ACR_ID `
  --only-show-errors | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Unable to assign the ACR quick-build role to the GitHub Actions identity."
}
Write-Output "ACR quick-build role assigned to the GitHub Actions identity."

# Assign the ACR pull role to the cluster
az role assignment create `
--assignee-object-id $env:KUBELET_OBJECT_ID `
--assignee-principal-type ServicePrincipal `
--role "AcrPull" `
--scope $env:ACR_ID
Write-Output "ACR pull role assigned. Waiting for propagation..."
Start-Sleep -Seconds 60

# Get the Key Vault addon identity
$env:IDENTITY_CLIENT_ID = az aks show `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" `
  -o tsv
Write-Output "Identity Client ID: $env:IDENTITY_CLIENT_ID"
# Get Key Vault scope
$env:KV_SCOPE = az keyvault show `
  --name $env:KV_NAME `
  --query "id" `
  -o tsv
# Assign Key Vault Secrets User role to the managed identity
az role assignment create `
  --role "Key Vault Secrets User" `
  --assignee $env:IDENTITY_CLIENT_ID `
  --scope $env:KV_SCOPE
Write-Output "✅ Permissions granted to managed identity successfully"

# install ARC controller

helm upgrade --install arc oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller `
  --version 0.14.2 `
  --namespace "$env:ARC_SYSTEMS_NAMESPACE" `
  --create-namespace `
  --wait `
  --timeout 10m `
  -f (Join-Path $PSScriptRoot "arc-controller-values.yaml")
if ($LASTEXITCODE -ne 0) {
  throw "ARC controller installation failed. Review the arc-systems namespace events for details."
}
Write-Output "ARC controller installed and deployment rolled out successfully."

kubectl rollout status deployment/arc-gha-rs-controller --namespace "$env:ARC_SYSTEMS_NAMESPACE" --timeout 5m
if ($LASTEXITCODE -ne 0) {
  throw "ARC controller rollout did not complete successfully."
}
Write-Output "ARC controller rollout status checked."

# create a namespace for the runner resources and store the GitHub token in a Kubernetes secret
kubectl create namespace "$env:ARC_RUNNERS_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
Write-Output "Namespace for runner resources created successfully."

kubectl create secret generic github-pat `
  --namespace $env:ARC_RUNNERS_NAMESPACE `
  --from-literal="github_token=$env:GITHUB_TOKEN" `
  --dry-run=client -o yaml |
  kubectl apply -f -
Write-Output "GitHub token stored in Kubernetes secret successfully."

# install runner scale set
helm upgrade --install "$env:RUNNER_SET_NAME" oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set `
  --version 0.14.2 `
  --namespace "$env:ARC_RUNNERS_NAMESPACE" `
  --create-namespace `
  --wait `
  --timeout 10m `
  --set-string "githubConfigUrl=$env:GITHUB_CONFIG_URL" `
  -f (Join-Path $PSScriptRoot "arc-runner-set-values.yaml")
if ($LASTEXITCODE -ne 0) {
  throw "ARC runner scale set installation failed. Review the arc-runners namespace events for details."
}
Write-Output "Runner scale set installed successfully."

# check install
kubectl get pods --namespace "$env:ARC_SYSTEMS_NAMESPACE" -o wide
kubectl get autoscalingrunnersets,ephemeralrunnersets,ephemeralrunners --namespace "$env:ARC_RUNNERS_NAMESPACE"
Write-Output "Before any jobs run, the controller and listener pods should be running and the AutoscalingRunnerSet should exist"


# store resource names in .envrc file
@"
export RAND=$env:RAND
export LOCATION=$env:LOCATION
export RG_NAME=$env:RG_NAME
export AKS_NAME=$env:AKS_NAME
export K8S_VERSION=$env:K8S_VERSION
export ACR_NAME=$env:ACR_NAME
export ACR_ID=$env:ACR_ID
export ACR_LOGIN_SERVER=$env:ACR_LOGIN_SERVER
export USER_ASSIGNED_IDENTITY_NAME=$env:USER_ASSIGNED_IDENTITY_NAME
export USER_ASSIGNED_IDENTITY_ID=$env:USER_ASSIGNED_IDENTITY_ID
export KUBELET_OBJECT_ID=$env:KUBELET_OBJECT_ID

export IDENTITY_CLIENT_ID=$env:IDENTITY_CLIENT_ID
export KV_SCOPE=$env:KV_SCOPE
export GITHUB_REPOSITORY=$env:GITHUB_REPOSITORY

export AZURE_TENANT_ID=$env:AZURE_TENANT_ID
export AZURE_SUBSCRIPTION_ID=$env:AZURE_SUBSCRIPTION_ID
"@ | Out-File -FilePath ".envrc" -Encoding utf8
Write-Output ".envrc file created with resource names."