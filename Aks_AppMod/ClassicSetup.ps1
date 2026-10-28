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
$env:RG_NAME = "rg-caldova$RAND"
Write-Output "Resource group name: $env:RG_NAME"

#set name suffix
$env:NAME_SUFFIX = "$RAND"
Write-Output "Name suffix set to: $env:NAME_SUFFIX"

# Create short suffix (first 6 characters) for resource names with length limits
$SHORT_SUFFIX = $env:NAME_SUFFIX.Substring(0, [Math]::Min(6, $env:NAME_SUFFIX.Length))

# Capture subscription ID for subscription-scope role assignments
$env:AZURE_SUBSCRIPTION_ID = az account show --query id -o tsv
Write-Output "Subscription ID: $env:AZURE_SUBSCRIPTION_ID"
$env:AZURE_TENANT_ID = az account show --query tenantId -o tsv
Write-Output "Tenant ID: $env:AZURE_TENANT_ID"
$subscriptionScope = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID"

# set resource names
$env:AKS_CLUSTER_NAME = "aks-caldova-$env:NAME_SUFFIX"
$env:AKS_NAME = $env:AKS_CLUSTER_NAME  # Alias for compatibility
$env:POSTGRES_SERVER_NAME = "db-caldova$SHORT_SUFFIX"
$env:POSTGRES_DATABASE_NAME = "caldova"
$env:USER_ASSIGNED_IDENTITY_NAME = "mi-caldova$SHORT_SUFFIX"
$env:ACR_NAME = "acrcaldova$SHORT_SUFFIX"

# register preview features
az extension add --name aks-preview
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

# CREATE THE RESOURCE GROUP FIRST
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

# Create the PostgreSQL Flexible Server
az postgres flexible-server create `
    --name $env:POSTGRES_SERVER_NAME `
    --resource-group $env:RG_NAME `
    --location $env:LOCATION `
    --admin-user petclinicadmin `
    --admin-password "Petclinic@$RAND!" `
    --sku-name Standard_B1ms `
    --tier Burstable `
    --version 15 `
    --storage-size 32 `
    --zonal-resiliency Disabled `
    --storage-auto-grow Enabled `
    --microsoft-entra-auth Enabled `
    --password-auth Disabled

az postgres flexible-server db create `
  --resource-group $env:RG_NAME `
  --server-name $env:POSTGRES_SERVER_NAME `
  --database-name $env:POSTGRES_DATABASE_NAME

# Capture database ID
$env:POSTGRES_DATABASE_ID=$(az postgres flexible-server db show `
  --resource-group $env:RG_NAME `
  --server-name $env:POSTGRES_SERVER_NAME `
  --database-name $env:POSTGRES_DATABASE_NAME `
  --query id `
  --output tsv)

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

# Create Log Analytics Workspace
$env:LOG_WORKSPACE_NAME = "mylogs$env:NAME_SUFFIX"
Write-Output "Creating Log Analytics Workspace: $env:LOG_WORKSPACE_NAME"
az monitor log-analytics workspace create `
  --resource-group $env:RG_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
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
$env:APP_INSIGHTS_NAME = "myappinsights$NAME_SUFFIX"
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

# create aks cluster
az aks create `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--location $env:LOCATION `
--tier standard `
--kubernetes-version $env:K8S_VERSION `
--os-sku AzureLinux `
--attach-acr $env:ACR_NAME `
--nodepool-name systempool `
--node-count 3 `
--load-balancer-sku standard `
--network-plugin azure `
--network-plugin-mode overlay `
--network-dataplane cilium `
--network-policy cilium `
--enable-managed-identity `
--enable-workload-identity `
--enable-oidc-issuer `
--enable-acns `
--enable-addons monitoring `
--enable-container-network-logs `
--acns-advanced-networkpolicies L7 `
--enable-high-log-scale-mode `
--generate-ssh-keys
Write-Output "AKS Cluster $env:AKS_NAME created successfully in resource group $env:RG_NAME"

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

# add user nodepool
az aks nodepool add `
--resource-group $env:RG_NAME `
--cluster-name $env:AKS_NAME `
--mode User `
--name userpool `
--node-count 2
Write-Output "User nodepool added to AKS Cluster $env:AKS_NAME"

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
Write-Output "✅ Permissions granted to managed identity"

# install the Service Connector extension
az extension add --name serviceconnector-passwordless --upgrade
Write-Output "Azure Service Connector extension installed."

# Allow public access from any Azure service and your IP
az postgres flexible-server firewall-rule create `
  --resource-group $env:RG_NAME `
  --name $env:POSTGRES_SERVER_NAME `
  --rule-name "AllowAll" `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 255.255.255.255
Write-Output "Firewall rule 'AllowAll' created for PostgreSQL Flexible Server $env:POSTGRES_SERVER_NAME"

# Create the service-connector for postgres-flexible
az aks connection create postgres-flexible --connection pg `
--source-id $env:AKS_CLUSTER_ID `
--target-id $env:POSTGRES_DATABASE_ID `
--workload-identity $env:USER_ASSIGNED_IDENTITY_ID `
--client-type none `
--kube-namespace default | tee sc.log
Write-Output "Azure Service Connector for PostgreSQL Flexible Server created."

# Get your Azure tenant ID
$env:TENANT_ID = az account show --query "tenantId" -o tsv
Write-Output "Tenant ID: $env:TENANT_ID"

#fetch setup-local-lab-infr
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Azure-Samples/aks-labs/refs/heads/main/docs/migration/assets/migrate-to-aks/setup-local-lab-infra.sh" -OutFile "setup-local-lab-infra.sh"

# store resource names in .envrc file
@"
export AKS_CLUSTER_NAME=$env:AKS_CLUSTER_NAME
export POSTGRES_SERVER_NAME=$env:POSTGRES_SERVER_NAME
export POSTGRES_DATABASE_NAME=$env:POSTGRES_DATABASE_NAME
export USER_ASSIGNED_IDENTITY_NAME=$env:USER_ASSIGNED_IDENTITY_NAME
export ACR_NAME=$env:ACR_NAME
"@| Out-File -FilePath ".envrc" -Encoding utf8
Write-Output ".envrc file created with resource names."

# in bash
# wsl bash ./setup-local-lab-infra.sh
# wsl bash -c "sudo apt update && sudo apt install -y openjdk-17-jdk"
# wsl bash -c "sudo apt update && sudo apt install -y docker.io && sudo service docker start && sudo usermod -aG docker $USER"