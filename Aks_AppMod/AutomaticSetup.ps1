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

# Setup AKS Cluster
$env:AKS_NAME = "aks-caldova-$RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"
# set PostgreSQL server and database names
$env:POSTGRES_SERVER_NAME = "db-caldova$SHORT_SUFFIX"
$env:POSTGRES_DATABASE_NAME = "caldova"
$env:USER_ASSIGNED_IDENTITY_NAME = "mi-caldova$SHORT_SUFFIX"
$env:ACR_NAME = "acrcaldova$SHORT_SUFFIX"
$env:MANAGED_NAMESPACE_NAME = "caldova"
$env:GATEWAY_NAMESPACE = $env:MANAGED_NAMESPACE_NAME
$env:GATEWAY_NAME = "shared-gateway"

$azureCliVersion = [version]((az version --output json | ConvertFrom-Json).'azure-cli')
if ($azureCliVersion -lt [version]"2.86.0") {
  throw "Azure CLI 2.86.0 or newer is required to enable the AKS Application Routing Gateway API. Installed version: $azureCliVersion"
}

# Note: 'az cognitiveservices' is built into the Azure CLI core - no extension is required.
# Ensure the Cognitive Services resource provider is registered instead.
az provider register --namespace Microsoft.CognitiveServices --wait
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

# Get the current user's object ID 
$env:USER_OBJECT_ID = az ad signed-in-user show --query "id" -o tsv
Write-Output "User Object ID: $env:USER_OBJECT_ID"
$env:USER_PRINCIPAL_NAME = az ad signed-in-user show --query "userPrincipalName" -o tsv
Write-Output "User Principal Name: $env:USER_PRINCIPAL_NAME"

# Restrict initial PostgreSQL access to the machine running this script.
$callerPublicIp = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
if ($callerPublicIp -notmatch '^(?:\d{1,3}\.){3}\d{1,3}$') {
  throw "Unable to determine a valid caller public IPv4 address."
}
Write-Output "PostgreSQL caller firewall address: $callerPublicIp"

# Create the PostgreSQL Flexible Server
az postgres flexible-server create `
    --name $env:POSTGRES_SERVER_NAME `
    --resource-group $env:RG_NAME `
    --location $env:LOCATION `
    --admin-display-name $env:USER_PRINCIPAL_NAME `
    --admin-object-id $env:USER_OBJECT_ID `
    --admin-type User `
    --sku-name Standard_B1ms `
    --tier Burstable `
    --version 15 `
    --storage-size 32 `
    --zonal-resiliency Disabled `
    --storage-auto-grow Enabled `
    --microsoft-entra-auth Enabled `
    --password-auth Disabled `
    --public-access $callerPublicIp

$env:POSTGRES_FQDN = az postgres flexible-server show `
  --resource-group $env:RG_NAME `
  --name $env:POSTGRES_SERVER_NAME `
  --query fullyQualifiedDomainName `
  --output tsv
write-output "PostgreSQL FQDN: $env:POSTGRES_FQDN"

az postgres flexible-server firewall-rule create `
  --server-name $env:POSTGRES_SERVER_NAME `
  --resource-group $env:RG_NAME `
  --name AllowMyCurrentIP `
  --start-ip-address $callerPublicIp `
  --end-ip-address $callerPublicIp
write-output "PostgreSQL firewall rule AllowMyCurrentIP created successfully."

az postgres flexible-server db create `
  --resource-group $env:RG_NAME `
  --server-name $env:POSTGRES_SERVER_NAME `
  --name $env:POSTGRES_DATABASE_NAME
write-output "PostgreSQL database $env:POSTGRES_DATABASE_NAME created successfully."

# Capture database ID
$env:POSTGRES_DATABASE_ID=$(az postgres flexible-server db show `
  --resource-group $env:RG_NAME `
  --server-name $env:POSTGRES_SERVER_NAME `
  --name $env:POSTGRES_DATABASE_NAME `
  --query id `
  --output tsv)
write-output "PostgreSQL database ID: $env:POSTGRES_DATABASE_ID"

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

# Permit only the effective AKS egress addresses to reach PostgreSQL.
$aksNetworkProfileJson = az aks show `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --query "{outboundType:networkProfile.outboundType,nodeResourceGroup:nodeResourceGroup,loadBalancerPublicIpIds:networkProfile.loadBalancerProfile.effectiveOutboundIPs[].id}" `
  --output json
if ($LASTEXITCODE -ne 0) {
  throw "Unable to inspect the AKS outbound network profile."
}
$aksNetworkProfile = $aksNetworkProfileJson | ConvertFrom-Json

$aksOutboundIpResourceIds = @()
switch ($aksNetworkProfile.outboundType) {
  "loadBalancer" {
    $aksOutboundIpResourceIds = @($aksNetworkProfile.loadBalancerPublicIpIds) | Where-Object { $_ }
  }
  "managedNATGateway" {
    $natGatewayResourceIds = @(
      az network vnet list `
        --resource-group $aksNetworkProfile.nodeResourceGroup `
        --query "[].subnets[].natGateway.id" `
        --output tsv
    ) | Where-Object { $_ } | Sort-Object -Unique
    if ($LASTEXITCODE -ne 0) {
      throw "Unable to inspect NAT gateways attached to the AKS subnets."
    }

    foreach ($natGatewayResourceId in $natGatewayResourceIds) {
      $aksOutboundIpResourceIds += @(
        az network nat gateway show `
          --ids $natGatewayResourceId `
          --query "publicIpAddresses[].id" `
          --output tsv
      ) | Where-Object { $_ }
      if ($LASTEXITCODE -ne 0) {
        throw "Unable to inspect AKS NAT gateway '$natGatewayResourceId'."
      }
    }
  }
  default {
    throw "AKS outbound type '$($aksNetworkProfile.outboundType)' is not supported for PostgreSQL firewall configuration."
  }
}

if ($aksOutboundIpResourceIds.Count -eq 0) {
  throw "AKS did not report any effective outbound public IP resources."
}

$aksOutboundIps = @()
foreach ($publicIpResourceId in $aksOutboundIpResourceIds) {
  $aksOutboundIp = az network public-ip show `
    --ids $publicIpResourceId `
    --query ipAddress `
    --output tsv
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to resolve AKS outbound public IP resource '$publicIpResourceId'."
  }
  if ($aksOutboundIp) {
    $aksOutboundIps += $aksOutboundIp
  }
}

if ($aksOutboundIps.Count -eq 0) {
  throw "Unable to resolve the effective AKS outbound public IP addresses."
}

$firewallRuleIndex = 1
foreach ($aksOutboundIp in $aksOutboundIps | Sort-Object -Unique) {
  az postgres flexible-server firewall-rule create `
    --resource-group $env:RG_NAME `
    --server-name $env:POSTGRES_SERVER_NAME `
    --name "AllowAksEgress$firewallRuleIndex" `
    --start-ip-address $aksOutboundIp `
    --end-ip-address $aksOutboundIp
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to allow AKS outbound IP '$aksOutboundIp' through the PostgreSQL firewall."
  }
  $firewallRuleIndex++
}

# Create the workload identity as a PostgreSQL principal and initialize its least-privilege schema grants.
$databaseBootstrapFile = Join-Path $PSScriptRoot "Scenario1App\CaldovaClinicalApi\db\init.sql"
if (-not (Test-Path $databaseBootstrapFile)) {
  throw "Database bootstrap file not found: $databaseBootstrapFile"
}

$databaseRoleSql = @"
DO `$`$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_roles
    WHERE rolname = '$env:USER_ASSIGNED_IDENTITY_NAME'
  ) THEN
    PERFORM pg_catalog.pgaadauth_create_principal_with_oid(
      '$env:USER_ASSIGNED_IDENTITY_NAME',
      '$env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID',
      'service',
      false,
      false
    );
  END IF;
END
`$`$;
"@
$databaseGrantSql = @"
GRANT CONNECT ON DATABASE $env:POSTGRES_DATABASE_NAME TO "$env:USER_ASSIGNED_IDENTITY_NAME";
GRANT USAGE ON SCHEMA pharmacy TO "$env:USER_ASSIGNED_IDENTITY_NAME";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA pharmacy TO "$env:USER_ASSIGNED_IDENTITY_NAME";
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA pharmacy TO "$env:USER_ASSIGNED_IDENTITY_NAME";
ALTER DEFAULT PRIVILEGES IN SCHEMA pharmacy GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "$env:USER_ASSIGNED_IDENTITY_NAME";
ALTER DEFAULT PRIVILEGES IN SCHEMA pharmacy GRANT USAGE, SELECT ON SEQUENCES TO "$env:USER_ASSIGNED_IDENTITY_NAME";
"@

try {
  $env:PGPASSWORD = az account get-access-token `
    --resource-type oss-rdbms `
    --query accessToken `
    --output tsv
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($env:PGPASSWORD)) {
    throw "Unable to acquire a Microsoft Entra access token for PostgreSQL."
  }

  az postgres flexible-server execute `
    --name $env:POSTGRES_SERVER_NAME `
    --admin-user $env:USER_PRINCIPAL_NAME `
    --admin-password $env:PGPASSWORD `
    --database-name $env:POSTGRES_DATABASE_NAME `
    --querytext $databaseRoleSql `
    --output none
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to create or verify the workload identity PostgreSQL principal."
  }

  az postgres flexible-server execute `
    --name $env:POSTGRES_SERVER_NAME `
    --admin-user $env:USER_PRINCIPAL_NAME `
    --admin-password $env:PGPASSWORD `
    --database-name $env:POSTGRES_DATABASE_NAME `
    --file-path $databaseBootstrapFile `
    --output none
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to initialize the PostgreSQL schema from '$databaseBootstrapFile'."
  }

  az postgres flexible-server execute `
    --name $env:POSTGRES_SERVER_NAME `
    --admin-user $env:USER_PRINCIPAL_NAME `
    --admin-password $env:PGPASSWORD `
    --database-name $env:POSTGRES_DATABASE_NAME `
    --querytext $databaseGrantSql `
    --output none
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to grant the workload identity access to the PostgreSQL schema."
  }
}
finally {
  Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

# Isolate Caldova workloads with explicit resource quotas and namespace-local ingress.
az aks namespace add `
  --resource-group $env:RG_NAME `
  --cluster-name $env:AKS_NAME `
  --name $env:MANAGED_NAMESPACE_NAME `
  --cpu-request 200m `
  --cpu-limit 400m `
  --memory-request 4Gi `
  --memory-limit 8Gi `
  --ingress-policy AllowSameNamespace `
  --egress-policy AllowAll
Write-Output "Managed Namespace $env:MANAGED_NAMESPACE_NAME created."

# Set kubeconfig path
$env:aksKubeConfigPath = "$env:USERPROFILE\.kube\config"

# Connect to the cluster
az aks get-credentials `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--file $env:aksKubeConfigPath `
--overwrite-existing
Write-Output "Connected to AKS Cluster $env:AKS_NAME"

# Set the KUBECONFIG environment variable to point to the AKS kubeconfig file
$env:KUBECONFIG = $env:aksKubeConfigPath
write-Output "KUBECONFIG environment variable set to: $env:KUBECONFIG"

# Retrieve the object ID of the AKS cluster's kubelet identity
$env:KUBELET_OBJECT_ID=$(az aks show `
    --name $env:AKS_NAME `
    --resource-group $env:RG_NAME `
    --query identityProfile.kubeletidentity.objectId `
    --output tsv)
write-Output "KUBELET_OBJECT_ID: $env:KUBELET_OBJECT_ID"

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
export USER_ASSIGNED_IDENTITY_NAME=$env:USER_ASSIGNED_IDENTITY_NAME
export USER_ASSIGNED_IDENTITY_ID=$env:USER_ASSIGNED_IDENTITY_ID
export USER_ASSIGNED_IDENTITY_CLIENT_ID=$env:USER_ASSIGNED_IDENTITY_CLIENT_ID
export USER_ASSIGNED_IDENTITY_PRINCIPAL_ID=$env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID
export KUBELET_OBJECT_ID=$env:KUBELET_OBJECT_ID
export POSTGRES_DATABASE_ID=$env:POSTGRES_DATABASE_ID
export POSTGRES_SERVER_NAME=$env:POSTGRES_SERVER_NAME
export POSTGRES_DATABASE_NAME=$env:POSTGRES_DATABASE_NAME
export POSTGRES_FQDN=$env:POSTGRES_FQDN
export POSTGRES_CALLER_FIREWALL_IP=$callerPublicIp
export POSTGRES_AKS_EGRESS_IPS=$($aksOutboundIps -join ',')
export MANAGED_NAMESPACE_NAME=$env:MANAGED_NAMESPACE_NAME
export GATEWAY_NAMESPACE=$env:GATEWAY_NAMESPACE
export GATEWAY_NAME=$env:GATEWAY_NAME
export IDENTITY_CLIENT_ID=$env:IDENTITY_CLIENT_ID
export KV_SCOPE=$env:KV_SCOPE
"@ | Out-File -FilePath ".envrc" -Encoding utf8
Write-Output ".envrc file created with resource names."