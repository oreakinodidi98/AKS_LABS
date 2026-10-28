# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND

# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"

# Set Location
$env:LOCATION = "swedencentral"
Write-Output "Location set to: $env:LOCATION"

# Capture subscription ID for subscription-scope role assignments
$env:AZURE_SUBSCRIPTION_ID = az account show --query id -o tsv
Write-Output "Subscription ID: $env:AZURE_SUBSCRIPTION_ID"
$env:AZURE_TENANT_ID = az account show --query tenantId -o tsv
Write-Output "Tenant ID: $env:AZURE_TENANT_ID"
$subscriptionScope = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID"

# Create a resource group name using the random number
$env:RG_NAME = "aksautofoundry$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# CREATE THE RESOURCE GROUP FIRST!
az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:RG_NAME created"

# Setup AKS Cluster
$env:AKS_NAME = "myakscluster$RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"

# Setup Foundry
$env:FOUNDRY_NAME = "ore-chatbot-foundry"
write-Output "Foundry name: $env:FOUNDRY_NAME"
$env:FOUNDRY_MODEL = "gpt-5.4-mini"
write-Output "Foundry model: $env:FOUNDRY_MODEL"
$env:FOUNDRY_MODEL_VERSION = "2026-03-17"
write-Output "Foundry model version: $env:FOUNDRY_MODEL_VERSION"
$env:FOUNDRY_SKU = "GlobalStandard"
write-Output "Foundry SKU: $env:FOUNDRY_SKU"
# Generate a short random name for user assigned identity (globally unique)
$env:CHAT_USER_ASSIGNED_IDENTITY_NAME = "chat-identity-$env:RAND"
Write-Output "User assigned identity name: $env:CHAT_USER_ASSIGNED_IDENTITY_NAME"
$env:FED_IDENTITY_NAME = "fed-identity-$env:RAND"
Write-Output "Federated identity name: $env:FED_IDENTITY_NAME"

# Note: 'az cognitiveservices' is built into the Azure CLI core - no extension is required.
# Ensure the Cognitive Services resource provider is registered instead.
az provider register --namespace Microsoft.CognitiveServices --wait

# Get the latest Kubernetes version available in the region
$env:K8S_VERSION=$(az aks get-versions -l $env:LOCATION `
--query "values[?isDefault==``true``].version | [0]" `
-o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"

# create aks cluster
az aks create `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--location $env:LOCATION `
--kubernetes-version $env:K8S_VERSION `
--sku automatic `
--no-ssh-key
Write-Output "AKS Cluster $env:AKS_NAME created successfully in resource group $env:RG_NAME"

az aks show --resource-group $env:RG_NAME --name $env:AKS_NAME --query hostedSystemProfile                               

# Set kubeconfig path
$env:aksKubeConfigPath = "$env:USERPROFILE\.kube\config"

# Connect to the cluster
az aks get-credentials `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--file $env:aksKubeConfigPath `
--overwrite-existing
Write-Output "Connected to AKS Cluster $env:AKS_NAME"

$env:KUBECONFIG = $env:aksKubeConfigPath
write-Output "KUBECONFIG environment variable set to: $env:KUBECONFIG"

$env:KUBELET_OBJECT_ID=$(az aks show `
    --name $env:AKS_NAME `
    --resource-group $env:RG_NAME `
    --query identityProfile.kubeletidentity.objectId `
    --output tsv)
write-Output "KUBELET_OBJECT_ID: $env:KUBELET_OBJECT_ID"

# Create Container Registry
$env:ACR_NAME = "oreacrregistry"
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
# Attach ACR to AKS cluster

# Assign the ACR pull role to the cluster
az role assignment create `
--assignee-object-id $env:KUBELET_OBJECT_ID `
--assignee-principal-type ServicePrincipal `
--role "AcrPull" `
--scope $env:ACR_ID
Write-Output "ACR pull role assigned. Waiting for propagation..."
Start-Sleep -Seconds 60

# foundry resource names
$env:FOUNDRY_ACCOUNT_NAME = "foundryaccount$RAND"  # Replace with your desired name
$env:PROJECT_NAME = "foundryproject$RAND"  # Replace with your desired name

# set up provider
az provider register --namespace Microsoft.CognitiveServices
Write-Output "Registered Microsoft.CognitiveServices provider"

# Create Foundry Account
az cognitiveservices account create `
  --name $env:FOUNDRY_ACCOUNT_NAME `
  --resource-group $env:RG_NAME `
  --location $env:LOCATION `
  --kind AIServices `
  --sku S0 `
  --custom-domain $env:FOUNDRY_ACCOUNT_NAME `
  --assign-identity `
  --yes
write-Output "Foundry account $env:FOUNDRY_ACCOUNT_NAME created successfully in resource group $env:RG_NAME"

# Deploy model 
az cognitiveservices account deployment create `
 --name $env:FOUNDRY_ACCOUNT_NAME `
 --resource-group $env:RG_NAME `
 --deployment-name $env:FOUNDRY_MODEL `
 --model-name $env:FOUNDRY_MODEL `
 --model-version $env:FOUNDRY_MODEL_VERSION `
 --model-format OpenAI `
 --sku-capacity 10 `
 --sku-name $env:FOUNDRY_SKU
write-Output "Foundry model $env:FOUNDRY_MODEL deployed successfully in account $env:FOUNDRY_ACCOUNT_NAME"

#  # Deploy model phi4 alternative
# az cognitiveservices account deployment create `
#  --name $env:FOUNDRY_ACCOUNT_NAME `
#  --resource-group $env:RG_NAME `
#  --deployment-name Phi-4-mini-instruct `
#  --model-name Phi-4-mini-instruct `
#  --model-version 1 `
#  --model-format Microsoft `
#  --sku-capacity 1 `
#  --sku-name $env:FOUNDRY_SKU

# Get the managed identity principal ID
$env:FOUNDRY_PRINCIPAL_ID = az cognitiveservices account identity show `
  --name $env:FOUNDRY_ACCOUNT_NAME `
  --resource-group $env:RG_NAME `
  --query "principalId" -o tsv
Write-Output "Foundry Principal ID: $env:FOUNDRY_PRINCIPAL_ID"

# Create the Chat user-assigned managed identity
az identity create --name $env:CHAT_USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --location $env:LOCATION
Write-Output "Chat user assigned managed identity $env:CHAT_USER_ASSIGNED_IDENTITY_NAME created in resource group $env:RG_NAME"
$env:CHAT_USER_ASSIGNED_IDENTITY_ID=$(az identity show --name $env:CHAT_USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'id' -o tsv)
$env:CHAT_USER_ASSIGNED_IDENTITY_CLIENT_ID=$(az identity show --name $env:CHAT_USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'clientId' -o tsv)
$env:CHAT_USER_ASSIGNED_IDENTITY_PRINCIPAL_ID=$(az identity show --name $env:CHAT_USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'principalId' -o tsv)
$managedIdentityScope = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID/resourceGroups/$env:RG_NAME/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$env:CHAT_USER_ASSIGNED_IDENTITY_NAME"
Write-Output "User assigned managed identity details stored."

# set permissions for kubectl 
az role assignment create `
--assignee-object-id $env:CHAT_USER_ASSIGNED_IDENTITY_PRINCIPAL_ID `
--assignee-principal-type ServicePrincipal `
--role "Cognitive Services User" `
--scope $subscriptionScope
Write-Output "Cognitive Services User assigned. Waiting for propagation..."
Start-Sleep -Seconds 60

# Get access token
$env:ACCESS_TOKEN = az account get-access-token --query accessToken -o tsv

# create service account in cluster
@"
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: $env:CHAT_USER_ASSIGNED_IDENTITY_CLIENT_ID
    azure.workload.identity/tenant-id: $env:AZURE_TENANT_ID
  labels:
    azure.workload.identity/use: "true"
  name: "oa-sa"
  namespace: default
"@ | kubectl apply -f -

# Show service account YAML manifest
kubectl get sa "oa-sa" -n default -o yaml

# Get the OIDC Issuer URL
$env:aksOidcIssuerUrl = $(az aks show `
    --only-show-errors `
    --name $env:AKS_NAME `
    --resource-group $env:RG_NAME `
    --subscription $env:AZURE_SUBSCRIPTION_ID  `
    --query oidcIssuerProfile.issuerUrl `
    --output tsv)
Write-Output "The OIDC Issuer URL of the $env:AKS_NAME cluster is $env:aksOidcIssuerUrl"

# create federated identity between the managed identity, the service account issuer, and the subject
  az identity federated-credential create `
    --name $env:FED_IDENTITY_NAME `
    --identity-name $env:CHAT_USER_ASSIGNED_IDENTITY_NAME `
    --resource-group $env:RG_NAME `
    --subscription $env:AZURE_SUBSCRIPTION_ID `
    --issuer $env:aksOidcIssuerUrl `
    --subject "system:serviceaccount:default:oa-sa"
Write-Output " federated identity between the managed identity, the service account issuer, and the subject has been created"

# Build and push the image in Azure Container Registry 
az acr build `
    --registry $env:ACR_NAME `
    --image "chatbot:v1" `
    --file Dockerfile `
    --subscription $env:AZURE_SUBSCRIPTION_ID `
    .

# deploy deployment file
kubectl apply -f deployment.yaml
write-Output "Deployment applied. Waiting for pods to be ready..."

# deploy service file
kubectl apply -f service.yaml
write-Output "Service applied. Waiting for service to be ready..."

# view external IP of the service
$serviceName = "mychatbot"
$namespace = "default"
$externalIP = ""
while (-not $externalIP) {
    $externalIP = kubectl get svc $serviceName -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    if (-not $externalIP) { Start-Sleep -Seconds 10 }
}
Write-Output "External IP of the service $serviceName is $externalIP"

# get Azure AI endpoilt url

az cognitiveservices account show `
  --name $env:FOUNDRY_ACCOUNT_NAME `
  --resource-group $env:RG_NAME `
  --query "properties.endpoint" -o tsv

# store resource names in .envrc file
@"
export RAND=$env:RAND
export LOCATION=$env:LOCATION
export RG_NAME=$env:RG_NAME
export AKS_NAME=$env:AKS_NAME
export K8S_VERSION=$env:K8S_VERSION
export aksKubeConfigPath=$env:aksKubeConfigPath
export ACR_NAME=$env:ACR_NAME
export ACR_ID=$env:ACR_ID
export ACR_LOGIN_SERVER=$env:ACR_LOGIN_SERVER
export FOUNDRY_ACCOUNT_NAME=$env:FOUNDRY_ACCOUNT_NAME
export PROJECT_NAME=$env:PROJECT_NAME
export FED_IDENTITY_NAME=$env:FED_IDENTITY_NAME
export aksOidcIssuerUrl=$env:aksOidcIssuerUrl
export FOUNDRY_PRINCIPAL_ID=$env:FOUNDRY_PRINCIPAL_ID
export FOUNDRY_MODEL=$env:FOUNDRY_MODEL
export FOUNDRY_MODEL_VERSION=$env:FOUNDRY_MODEL_VERSION
export FOUNDRY_SKU=$env:FOUNDRY_SKU
export ACCESS_TOKEN=$env:ACCESS_TOKEN
export CHAT_USER_ASSIGNED_IDENTITY_NAME=$env:CHAT_USER_ASSIGNED_IDENTITY_NAME
export CHAT_USER_ASSIGNED_IDENTITY_ID=$env:CHAT_USER_ASSIGNED_IDENTITY_ID
export CHAT_USER_ASSIGNED_IDENTITY_CLIENT_ID=$env:CHAT_USER_ASSIGNED_IDENTITY_CLIENT_ID
export CHAT_USER_ASSIGNED_IDENTITY_PRINCIPAL_ID=$env:CHAT_USER_ASSIGNED_IDENTITY_PRINCIPAL_ID
export KUBELET_OBJECT_ID=$env:KUBELET_OBJECT_ID
"@ | Out-File -FilePath ".envrc" -Encoding utf8
Write-Output ".envrc file created with resource names."