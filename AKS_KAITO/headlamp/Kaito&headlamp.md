# Running AI & LLM Models on AKS with KAITO and Headlamp

**KAITO** — Kubernetes AI Toolchain Operator

- Designed to automate AI/ML model inference and tuning workloads within Kubernetes clusters

---

## Why KAITO?

- Used for managing large model files using container images
- Provisions GPU node pools
- Providing preset configurations optimized for different GPU hardware
- Installs required NVIDIA GPU drivers
- Installs the device plugin for GPU
- Runs the model on GPU VMs using vLLM
- Supporting popular inference runtimes such as vLLM and transformers
- Exposes an endpoint for inference through a Kubernetes service
- Scales to meet customer demand
- Monitors GPU usage
- Supports RAG engine implementation
- Automating GPU node provisioning based on specific model requirements
- Hosting large model images in public registries when permissible

---

## KAITO Architecture

- KAITO follows the Kubernetes Custom Resource Definition (CRD) / controller design pattern
- It is formed of two controllers, Workspace and GPU provisioner
- User manages a workspace custom resource which describes the GPU requirements and the inference or tuning specification
- The GPU provisioner is built on top of Karpenter APIs and is responsible for provisioning GPU nodes
- When you submit a workspace custom resource to the Kubernetes API server, the Workspace controller creates a NodeClaim custom resource and waits for the GPU provisioner controller to provision a node and configures necessary GPU drivers and libraries to support the model — all of which would have been manual steps without KAITO
- KAITO controllers will automate the deployment by reconciling the workspace custom resource
- Once the GPU node is provisioned, the Workspace controller will proceed to deploy the inference workload using the specified configuration
- This configuration can be a custom Pod template that you create, but the best part of KAITO is its support for preset configurations
- Presets are pre-built, optimal GPU configuration for specific models
- The Workspace controller creates the Pod and proceeds to pull down the containerized model and run a model inference server which is exposed via a Kubernetes Service, allowing users to access it through a REST API
- KAITO presets the model configurations to avoid adjusting workload parameters based on GPU hardware
- Auto-provisions cost-effective GPU nodes based on model requirements
- KAITO provides an HTTP server to perform inference calls using the model library

---

## What is Headlamp?

**Headlamp** — A Kubernetes dashboard that gives you a graphical interface for managing your clusters

- Open-source project built by Microsoft
- Recently accepted into the core Kubernetes project under Kubernetes SIG UI
- Designed with extensibility in mind, you can customize and extend it with plugins
- Supports connecting to multiple clusters at once
- Provides real-time updates so you always see the current state of your resources
- Modern, intuitive interface that works for both beginners and experienced Kubernetes users

### KAITO + Headlamp

- KAITO provides a dedicated Headlamp plugin that adds specialized features for managing KAITO workspaces
- Makes it easy to deploy and monitor AI models directly from the dashboard, no need to jump between CLI and browser
- You get a visual way to manage your GPU workloads, check inference status, and monitor model deployments

#### Install KAITO Pluging

- open Headlamp
- Plugin cataloge
- Headlamp KAITO
- install and reload
- connect to cluster

### Deploy Workspace

- With the KAITO add-on installed, we can now deploy a workspace custom resource by clicking on the KAITO button on the toolbar
- Model Catalog will present a list of available preset Workspaces. These are the available models that you can deploy with KAITO
- Scroll down and page through the list of available models until you find the model you want ant, then click Deploy.
- A panel will open with the yamel manifest of the workspace
- Can deploy the default workspace or a customized workspace by modifying the YAML
  - The default worksapce is a preset configuration that has been optimized for the most cost effective VM size that meets the requirements of the model. Reccomended for most people
  - The customised workspace is users customising the workspace to use a different VM size if they have specific requirements or if they want to use a VM size that they have sufficient quota for
- After deployed check Kaito workspace to see progress . Make sure the Resource Ready, Inference Ready, and Workspace Ready statuses are all set to ready
- deployment can take up to 15 minutes

### Test Workspace

- can click on the chat menu in headlamp when workspaces is ready , this will allow you to test the infrence endpoint
- Select the workspace and model and begging testing , this also allows you to view workspace logs which is usefull for debugging and troubleshooting issues with he workspace
- can adjust the following prompt parameters in the settings icon
  - Temperature for controlling the randomness of the output
  - Max Tokens for controlling the maximum length of the output
  - Top P for controlling the diversity of the output
  - Top K for controlling the number of tokens to sample from
  - Repetition Penalty for controlling the penalty for repeating tokens

### Useful Links

- [Headlamp official website](https://headlamp.dev/) — downloads and documentation
- [Headlamp GitHub repository](https://github.com/headlamp-k8s/headlamp) — source code and contributions
- [Plugin development guide](https://headlamp.dev/docs/latest/development/plugins/) — for creating custom extensions

---

## Prerequisites

- [Headlamp](https://headlamp.dev/)
- [REST Client extension](https://marketplace.visualstudio.com/items?itemName=humao.rest-client)
- [UV](https://docs.astral.sh/uv/)
- Azure CLI with `aks-preview` extension
- Azure subscription with permissions to create resources

---

## Infrastructure Setup

> **Note:** The full setup script is available at [`setup.ps1`](setup.ps1). You can run it end-to-end or step through each section below.

### Step 1 — Variables and Resource Naming

Generate a random suffix for unique resource names and store them in an `.envrc` file for reference.

```powershell
# Generate a random number
$RAND = Get-Random
$env:RAND = $RAND
Write-Output "Random resource identifier will be: $RAND"

# Set Location
$env:LOCATION = "swedencentral"
Write-Output "Location set to: $env:LOCATION"

# Create a resource group name using the random number
$env:RG_NAME = "rg-aks-kaito-demo$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# Set name suffix
$env:NAME_SUFFIX = "$RAND"
Write-Output "Name suffix set to: $env:NAME_SUFFIX"

# Create short suffix (first 6 characters) for resource names with length limits
$SHORT_SUFFIX = $env:NAME_SUFFIX.Substring(0, [Math]::Min(6, $env:NAME_SUFFIX.Length))

# Set resource names
$env:AKS_CLUSTER_NAME = "aks-kaito-demo-$env:NAME_SUFFIX"
$env:AKS_NAME = $env:AKS_CLUSTER_NAME  # Alias for compatibility
$env:USER_ASSIGNED_IDENTITY_NAME = "mi-kaito-demo$SHORT_SUFFIX"
$env:ACR_NAME = "acrkaitodemo$SHORT_SUFFIX"

# Store resource names in .envrc file
$envrcContent = @"
export AKS_CLUSTER_NAME=$env:AKS_CLUSTER_NAME
export USER_ASSIGNED_IDENTITY_NAME=$env:USER_ASSIGNED_IDENTITY_NAME
export ACR_NAME=$env:ACR_NAME
"@ | Out-File -FilePath ".envrc" -Encoding utf8
Write-Output ".envrc file created with resource names."
```

### Step 2 — Preview Features and Provider Registration

Register required preview features and Azure resource providers before creating any resources.

```powershell
# Register preview features
az extension add --name aks-preview
az feature register --namespace "Microsoft.ContainerService" --name "AdvancedNetworkingFlowLogsPreview"
az feature register --namespace "Microsoft.ContainerService" --name "AdvancedNetworkingL7PolicyPreview"
Write-Output "Preview features registered. This may take a few minutes."

# Register required providers
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
```

### Step 3 — Resource Group

```powershell
az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:RG_NAME created"
```

### Step 4 — Kubernetes Version

Get the latest default Kubernetes version available in the region.

```powershell
$env:K8S_VERSION=$(az aks get-versions -l $env:LOCATION `
  --query "values[?isDefault==``true``].version | [0]" `
  -o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"
```

### Step 5 — User-Assigned Managed Identity

Create the identity and wait for propagation before capturing its details.

```powershell
az identity create `
  --name $env:USER_ASSIGNED_IDENTITY_NAME `
  --resource-group $env:RG_NAME `
  --location $env:LOCATION
Write-Output "User assigned managed identity $env:USER_ASSIGNED_IDENTITY_NAME created"

# Wait for identity propagation
Write-Output "Waiting for identity propagation..."
Start-Sleep -Seconds 30

$env:USER_ASSIGNED_IDENTITY_ID=$(az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'id' -o tsv)
$env:USER_ASSIGNED_IDENTITY_CLIENT_ID=$(az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'clientId' -o tsv)
$env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID=$(az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'principalId' -o tsv)
Write-Output "User assigned managed identity details stored."

# Get the current user's object ID for Key Vault permissions
$env:USER_OBJECT_ID = az ad signed-in-user show --query "id" -o tsv
Write-Output "User Object ID: $env:USER_OBJECT_ID"
```

### Step 6 — Azure Container Registry (ACR)

Create the ACR with Standard SKU, then enable system-assigned managed identity.

> **Note:** ACR names must be alphanumeric only (no hyphens or underscores), 5–50 characters.

```powershell
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
```

### Step 7 — Observability Stack

Set up Log Analytics, Azure Monitor (Prometheus), and Application Insights for full observability.

#### Log Analytics Workspace

```powershell
$env:LOG_WORKSPACE_NAME = "mylogs$env:NAME_SUFFIX"
Write-Output "Creating Log Analytics Workspace: $env:LOG_WORKSPACE_NAME"
az monitor log-analytics workspace create `
  --resource-group $env:RG_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
  --identity-type SystemAssigned `
  --location $env:LOCATION
Write-Output "Log Analytics Workspace $env:LOG_WORKSPACE_NAME created"

$env:LOG_WORKSPACE_ID = az monitor log-analytics workspace show `
  --resource-group $env:RG_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
  --query "id" -o tsv
Write-Output "Log Analytics Workspace ID: $env:LOG_WORKSPACE_ID"
```

#### Azure Monitor Workspace (Prometheus)

```powershell
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
```

#### Application Insights

```powershell
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
```

### Step 8 — Key Vault and RBAC

Create a Key Vault with RBAC authorization enabled and assign roles to the managed identity and current user.

```powershell
# Create Key Vault with RBAC enabled
$env:KV_NAME = "kv-$(Get-Random -Minimum 1000 -Maximum 9999)"
Write-Output "Creating Key Vault: $env:KV_NAME"
az keyvault create `
  --name $env:KV_NAME `
  --resource-group $env:RG_NAME `
  --location $env:LOCATION `
  --enable-rbac-authorization true `
  --sku standard
Write-Output "Azure Key Vault $env:KV_NAME created"

# Get Key Vault ID and URI
$env:KV_ID = az keyvault show --name $env:KV_NAME --query "id" -o tsv
$env:KV_URI = az keyvault show --name $env:KV_NAME --query "properties.vaultUri" -o tsv
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
```

### Step 9 — AKS Cluster Creation

Create the AKS cluster with Azure CNI Overlay, Cilium networking, workload identity, OIDC issuer, monitoring, and ACR integration.

```powershell
az aks create `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --location $env:LOCATION `
  --kubernetes-version $env:K8S_VERSION `
  --attach-acr $env:ACR_NAME `
  --load-balancer-sku standard `
  --network-plugin azure `
  --network-plugin-mode overlay `
  --network-dataplane cilium `
  --network-policy cilium `
  --enable-managed-identity `
  --enable-workload-identity `
  --enable-oidc-issuer `
  --enable-addons monitoring `
  --ssh-access disabled
Write-Output "AKS Cluster $env:AKS_NAME created successfully"
```

### Step 10 — Cluster Connection and Node Pool Configuration

Capture cluster details, connect to the cluster, add a user node pool, and taint the system node pool.

```powershell
# Capture AKS cluster details
$env:AKS_CLUSTER_ID = az aks show `
  --name $env:AKS_NAME `
  --resource-group $env:RG_NAME `
  --query id --output tsv
Write-Output "AKS Cluster ID: $env:AKS_CLUSTER_ID"

$env:AKS_CLUSTER_FQDN = az aks show `
  --name $env:AKS_NAME `
  --resource-group $env:RG_NAME `
  --query "fqdn" --output tsv
Write-Output "AKS Cluster FQDN: $env:AKS_CLUSTER_FQDN"

# Connect to the cluster
az aks get-credentials `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --overwrite-existing `
  --file "$env:AKS_NAME.config"
$env:KUBECONFIG = "$PWD\$env:AKS_NAME.config"
Write-Output "Connected to AKS Cluster $env:AKS_NAME"

```

### Step 11 — Key Vault Integration in AKS

Enable the Azure Key Vault Secrets Provider addon and grant the addon identity access to the Key Vault.

```powershell
# Enable Key Vault integration
az aks enable-addons `
  --addons azure-keyvault-secrets-provider `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME
Write-Output "Azure Key Vault Secrets Provider addon enabled"

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
  --query "id" -o tsv

# Assign Key Vault Secrets User role to the addon identity
az role assignment create `
  --role "Key Vault Secrets User" `
  --assignee $env:IDENTITY_CLIENT_ID `
  --scope $env:KV_SCOPE
Write-Output "Permissions granted to managed identity"
```

### Step 12 — Service Connector and Tenant ID

```powershell
# Install the Service Connector extension
az extension add --name serviceconnector-passwordless --upgrade
Write-Output "Azure Service Connector extension installed."

# Get Azure tenant ID
$env:TENANT_ID = az account show --query "tenantId" -o tsv
Write-Output "Tenant ID: $env:TENANT_ID"
```

---

## Install KAITO Add-on Using the AKS Extension (VS Code)

1. In VS Code, click on the Kubernetes extension icon in the left sidebar
2. In the Clouds section, expand the Azure section, then click on **Sign in to Azure**
3. Select your tenant
4. Right-click your AKS cluster, select **Deploy a LLM with KAITO** and click **Install KAITO**
5. The Install KAITO tab will open — click the **Install KAITO** button at the bottom
6. Installing KAITO can take up to 15 minutes to complete
7. Once the installation is complete, you will see a message indicating that KAITO has been installed successfully

## Developing AI Application by Interacting with the KAITO Workspace Endpoint

- After deploying the workspace, you can now start developing an AI application by interacting with the workspace endpoint
- This can be done by either HTTP requests or using a library that supports the OpenAI API

### Port Forward Workspace Service

- Your AI app needs to connect to the KAITO workspace Service
- This service is of type `ClusterIP` so runs as an internal service
- Meaning not accessible from outside the cluster
- But can access from local machine using port forwarding
- Can use the `kubectl port-forward` command or the Headlamp application to port-forward the workspace service

**To port forward in Headlamp:**

1. Go to the **Network** tab
2. Select the service for the workspace
3. Click **Port Forward**
4. A random port would be assigned to the service — this port will be used to connect to KAITO

---

## Monitoring

- Workspaces are served using the vLLM runtime
- Allows us to monitor the performance of the KAITO workspace using the metrics emitted by the vLLM server
- The metrics are emitted in the Prometheus format
- To view metrics that are emitted, go to the **/metrics** endpoint of the workspace service

