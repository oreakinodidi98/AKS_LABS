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
$env:RG_NAME = "aksresourcegroup$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# Setup AKS Cluster
$env:AKS_NAME = "aksmcpcluster$RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"

# Generate a short random name for user assigned identity (globally unique)
$env:USER_ASSIGNED_IDENTITY_NAME = "mcp-identity-$RAND"
Write-Output "User assigned identity name: $env:USER_ASSIGNED_IDENTITY_NAME"

# Generate a short random name for ACR (globally unique)
$env:ACR_NAME = "mcpacr$RAND"
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

# Get the current user's object ID for Key Vault permissions
$env:USER_OBJECT_ID = az ad signed-in-user show --query "id" -o tsv
Write-Output "User Object ID: $env:USER_OBJECT_ID"

# Create ACR
Write-Output "Creating Azure Container Registry: $env:ACR_NAME"
az acr create `
  --resource-group $env:RG_NAME `
  --name $env:ACR_NAME `
  --sku Basic `
  --location $env:LOCATION

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
--enable-workload-identity `
--enable-oidc-issuer `
--enable-acns `
--enable-addons monitoring `
--enable-container-network-logs `
--acns-advanced-networkpolicies L7 `
--enable-high-log-scale-mode `
--ssh-access disabled `
--generate-ssh-keys
Write-Output "AKS Cluster $env:AKS_NAME created successfully in resource group $env:RG_NAME with ssh-access disabled and workload identity enabled."

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

# Connect to the cluster
az aks get-credentials --resource-group $env:RG_NAME --name $env:AKS_NAME --overwrite-existing
Write-Output "Connected to AKS cluster $env:AKS_NAME."

# create service account
@"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aks-mcp
  annotations:
    azure.workload.identity/client-id: $env:USER_ASSIGNED_IDENTITY_CLIENT_ID
"@ | kubectl apply -f -
Write-Output "Service account 'aks-mcp' created and annotated with client ID of user assigned managed identity."
# The annotation azure.workload.identity/client-id is used to associate the Service Account with the managed identity. 
# This allows the pods that use this Service Account to authenticate to Azure using the managed identity

# Create a ClusterRoleBinding to bind the cluster admin role to the Service Account
@"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: aks-mcp-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: aks-mcp
    namespace: default
"@ | kubectl apply -f -
Write-Output "ClusterRoleBinding 'aks-mcp-cluster-admin' created to bind cluster-admin role to Service Account 'aks-mcp'."
# Granting the Service Account a broad set of permissions that may exceed the minimum required for the MCP server to function
# In a production environment, you should follow the principle of least privilege and assign only the necessary permissions required for your use case

# Deploy the AKS MCP server as a Deployment and Service in the AKS cluster
@"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-mcp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aks-mcp
  template:
    metadata:
      labels:
        app: aks-mcp
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: aks-mcp
      containers:
      - name: aks-mcp
        image: ghcr.io/azure/aks-mcp:v0.0.17
        args:
          - --access-level=readwrite
          - --transport=streamable-http
          - --host=0.0.0.0
          - --port=8000
          - --timeout=600
        ports:
        - containerPort: 8000
          name: http
        resources: {}
"@ | kubectl apply -f -
Write-Output "AKS MCP server deployed as a Deployment in the AKS cluster."
# AKS MCP server is deployed with readwrite access, which enables the MCP server to manage resources in the cluster and on Azure
# This is only for demonstration purposes. 
# In a production environment, you should follow the principle of least privilege and configure the MCP server with only the necessary access level required for your use case

# check pod
kubectl get pods -l app=aks-mcp
Write-Output "AKS MCP server pod status checked."

# check logs
kubectl logs deploy/aks-mcp
Write-Output "AKS MCP server logs retrieved."
# MCP server is using the federated token for authentication, which means that Workload Identity is working correctly

# Service 
@"
apiVersion: v1
kind: Service
metadata:
  name: aks-mcp
spec:
  type: ClusterIP
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
    name: http
  selector:
    app: aks-mcp
"@ | kubectl apply -f -
Write-Output "Service 'aks-mcp' created for AKS MCP server. Created an internal ClusterIP service that exposes the MCP server on port 8000"

# port-forwarding the service to your local machine and using the MCP Inspector tool to connect to it.
kubectl port-forward svc/aks-mcp 8000:8000 &
Write-Output "Port forwarding established for service 'aks-mcp' on port 8000. You can now connect to the MCP server using the MCP Inspector tool the & at the end to move the process to the background"
Write-Output "This service is only accessible within the AKS cluster."
# Port-forwarding allows you to access the service from your local machine for testing purposes. 
# In a production environment, you would typically expose the service using an Ingress controller.

# Using the MCP Inspector tool to test the MCP server
npx @modelcontextprotocol/inspector
Write-Output "MCP Inspector tool launched. You can now interact with the MCP server using the tool's interface."

# Populate the following fields in the tool
write-host "To connect to the MCP server, use the following details in the MCP Inspector tool:In the MCP Inspector tool, you will need to populate a few fields to connect:

Transport Type: Select Streamable HTTP.
URL: Enter http://localhost:8000/mcp.
connect to the AKS MCP server "

# view tools
write-host " click Tools and then click on List Tools to see the list of available tools. Can click on a tool to see details of tool "

write-host "You've successfully deployed the AKS MCP server on AKS as a Streamable HTTP service with Workload Identity"