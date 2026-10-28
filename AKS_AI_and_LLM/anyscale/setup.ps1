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
$SHORT_SUFFIX = $env:NAME_SUFFIX.Substring(0, [Math]::Min(6, $env:NAME_SUFFIX.Length))

# Set Location
$env:LOCATION = "swedencentral"
Write-Output "Location set to: $env:LOCATION"

# Create a resource group name using the random number
$env:RG_NAME = "rg-anyscale-$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# Setup AKS Cluster
$env:AKS_NAME = "anyscale-aks-cluster$RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"

# Generate a short random name for user assigned identity (globally unique)
$env:USER_ASSIGNED_IDENTITY_NAME = "anyscale-identity-$RAND"
Write-Output "User assigned identity name: $env:USER_ASSIGNED_IDENTITY_NAME"

# Generate a short random name for ACR (globally unique)
$env:ACR_NAME = "anyscaleacr$SHORT_SUFFIX"
Write-Output "ACR name: $env:ACR_NAME"


# CREATE THE RESOURCE GROUP FIRST!
az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:RG_NAME created"

# Get the latest Kubernetes version available in the region
$env:K8S_VERSION=$(az aks get-versions -l $env:LOCATION `
--query "values[?isDefault==``true``].version | [0]" `
-o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"

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

# create aks cluster
Write-Output "Creating AKS Cluster: $env:AKS_NAME with  OIDC issuer and workload identity enabled"
az aks create `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--location $env:LOCATION `
--kubernetes-version $env:K8S_VERSION `
--attach-acr $env:ACR_NAME `
--node-count 3 `
--node-vm-size Standard_D4s_v5 `
--load-balancer-sku standard `
--network-plugin azure `
--network-plugin-mode overlay `
--network-dataplane cilium `
--network-policy cilium `
--enable-managed-identity `
--enable-workload-identity `
--enable-oidc-issuer `
--enable-addons monitoring,azure-keyvault-secrets-provider `
--enable-container-network-logs `
--generate-ssh-keys
Write-Output "AKS Cluster $env:AKS_NAME created successfully in resource group $env:RG_NAME with workload identity enabled and attached to ACR $env:ACR_NAME."

# create node pool
# Ray head nodes and worker nodes share the default node pool. 
# For production workloads, create dedicated AKS node pools for Ray workloads 
# and use Kubernetes taints and tolerations to steer Ray pods to those nodes
# Will apply a Apply a NoSchedule taint to the dedicated node pool to prevent non-Ray workloads from scheduling on it.
az aks nodepool add --name rayworkers `
--resource-group $env:RG_NAME `
--cluster-name $env:AKS_NAME `
--node-vm-size Standard_NC24ads_A100_v4 `
--tags EnableManagedGPUExperience=true `
--node-count 1 `
--priority Regular `
--enable-cluster-autoscaler `
--min-count 1 `
--max-count 3 `
--node-taints "sku=gpu:NoSchedule" `
--labels workload=ray-cluster
Write-Output "Node pool 'rayworkers' created successfully."

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

# Connect to the cluster
az aks get-credentials `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --overwrite-existing `
  --file "$env:AKS_NAME.config"
$env:KUBECONFIG = "$PWD\$env:AKS_NAME.config"
Write-Output "Connected to AKS Cluster $env:AKS_NAME"

# store resource names in .envrc file
$envrcContent = @"
export RG_NAME=$env:RG_NAME
export LOCATION=$env:LOCATION
export AKS_NAME=$env:AKS_NAME
export USER_ASSIGNED_IDENTITY_NAME=$env:USER_ASSIGNED_IDENTITY_NAME
export ACR_NAME=$env:ACR_NAME
export NAME_SUFFIX=$env:NAME_SUFFIX
export SHORT_SUFFIX=$env:SHORT_SUFFIX
export K8S_VERSION=$env:K8S_VERSION
export AKS_CLUSTER_ID=$env:AKS_CLUSTER_ID
export AKS_CLUSTER_FQDN=$env:AKS_CLUSTER_FQDN
"@ | Out-File -FilePath ".envrc" -Encoding utf8
Write-Output ".envrc file created with resource names."

# instal Envoy Gateway with Helm
helm install eg oci://docker.io/envoyproxy/gateway-helm `
    --version v1.7.0 `
    --namespace envoy-gateway-system `
    --create-namespace