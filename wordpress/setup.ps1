#### Step 1 Define Enviroment Variables ####

$env:SSL_EMAIL_ADDRESS="$(az account show --query user.name --output tsv)"
Write-Output "SSL Email Address: $env:SSL_EMAIL_ADDRESS"
$env:NETWORK_PREFIX="$(($RANDOM % 253 + 1))"
Write-Output "Network Prefix: $env:NETWORK_PREFIX"
$env:RANDOM_ID="$(openssl rand -hex 3)"
Write-Output "Random ID: $env:RANDOM_ID"
$env:MY_RESOURCE_GROUP_NAME="myWordPressAKSResourceGroup$env:RANDOM_ID"
Write-Output "Resource Group Name: $env:MY_RESOURCE_GROUP_NAME"
$env:REGION="swedencentral"
$env:MY_AKS_CLUSTER_NAME="myAKSCluster$env:RANDOM_ID"
Write-Output "AKS Cluster Name: $env:MY_AKS_CLUSTER_NAME"
$env:MY_PUBLIC_IP_NAME="myPublicIP$env:RANDOM_ID"
Write-Output "Public IP Name: $env:MY_PUBLIC_IP_NAME"
$env:MY_DNS_LABEL="mydnslabel$env:RANDOM_ID"
Write-Output "DNS Label: $env:MY_DNS_LABEL"
$env:MY_VNET_NAME="myVNet$env:RANDOM_ID"
Write-Output "VNet Name: $env:MY_VNET_NAME"
$env:MY_VNET_PREFIX="10.$env:NETWORK_PREFIX.0.0/16"
Write-Output " VNet Prefix: $env:MY_VNET_PREFIX"
$env:MY_SN_NAME="mySN$env:RANDOM_ID"
Write-Output " Subnet Name: $env:MY_SN_NAME"
$env:MY_SN_PREFIX="10.$env:NETWORK_PREFIX.0.0/22"
Write-Output " Subnet Prefix: $env:MY_SN_PREFIX"
$env:MY_APPGW_SN_NAME="myAppGwSN$env:RANDOM_ID"
Write-Output " App Gateway Subnet Name: $env:MY_APPGW_SN_NAME"
$env:MY_APPGW_SN_PREFIX="10.$env:NETWORK_PREFIX.4.0/22"
Write-Output " App Gateway Subnet Prefix: $env:MY_APPGW_SN_PREFIX"
$env:MY_VM_SN_NAME="myVMSN$env:RANDOM_ID"
Write-Output " VM Subnet Name: $env:MY_VM_SN_NAME"
$env:MY_VM_SN_PREFIX="10.$env:NETWORK_PREFIX.8.0/22"
Write-Output " VM Subnet Prefix: $env:MY_VM_SN_PREFIX"
$env:MY_MYSQL_DB_NAME="mydb$env:RANDOM_ID"
Write-Output " MySQL Database Name: $env:MY_MYSQL_DB_NAME"
$env:MY_MYSQL_ADMIN_USERNAME="dbadmin$env:RANDOM_ID"
Write-Output " MySQL Admin Username: $env:MY_MYSQL_ADMIN_USERNAME"
$env:MY_MYSQL_ADMIN_PW="$(openssl rand -base64 32)"
Write-Output " MySQL Admin Password: $env:MY_MYSQL_ADMIN_PW"
$env:MY_MYSQL_SN_NAME="myMySQLSN$env:RANDOM_ID"
Write-Output " MySQL Subnet Name: $env:MY_MYSQL_SN_NAME"
$env:MY_MYSQL_HOSTNAME="$env:MY_MYSQL_DB_NAME.mysql.database.azure.com"
Write-Output " MySQL Hostname: $env:MY_MYSQL_HOSTNAME"
$env:MY_WP_ADMIN_PW="$(openssl rand -base64 32)"
Write-Output " WordPress Admin Password: $env:MY_WP_ADMIN_PW"
$env:MY_WP_ADMIN_USER="wpcliadmin"
Write-Output " MySQL Admin Username: $env:MY_WP_ADMIN_USER"
$env:FQDN="$env:MY_DNS_LABEL.$env:REGION.cloudapp.azure.com"
Write-Output " FQDN: $env:FQDN"

# CREATE RESOURCE GROUP 
az group create --name $env:MY_RESOURCE_GROUP_NAME --location $env:REGION
Write-Output "Resource group $env:MY_RESOURCE_GROUP_NAME created"

# Create a virtual network and subnet
az network vnet create --resource-group $env:MY_RESOURCE_GROUP_NAME --name $env:MY_VNET_NAME --address-prefix $env:MY_VNET_PREFIX --subnet-name $env:MY_SN_NAME --subnet-prefix $env:MY_SN_PREFIX
Write-Output "Virtual network $env:MY_VNET_NAME and subnet $env:MY_SN_NAME created"

az network vnet subnet create `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --vnet-name $env:MY_VNET_NAME `
  --name $env:MY_SN_NAME `
  --address-prefixes $env:MY_SN_PREFIX
Write-Output "Subnet $env:MY_SN_NAME created"

az network vnet subnet create `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --vnet-name $env:MY_VNET_NAME `
  --name $env:MY_APPGW_SN_NAME `
  --address-prefixes $env:MY_APPGW_SN_PREFIX
Write-Output "Subnet $env:MY_APPGW_SN_NAME created"

az network vnet subnet create `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --vnet-name $env:MY_VNET_NAME `
  --name $env:MY_VM_SN_NAME `
  --address-prefixes $env:MY_VM_SN_PREFIX
Write-Output "Subnet $env:MY_VM_SN_NAME created"

# Create a Azure Database for MySQL Flexible Server instance
az mysql flexible-server create --admin-password $env:MY_MYSQL_ADMIN_PW --admin-user $env:MY_MYSQL_ADMIN_USERNAME --auto-scale-iops Disabled --high-availability Disabled --iops 500 --location $env:REGION --name $env:MY_MYSQL_DB_NAME --database-name wordpress --resource-group $env:MY_RESOURCE_GROUP_NAME --sku-name Standard_B2s --storage-auto-grow Disabled --storage-size 20 --subnet $env:MY_MYSQL_SN_NAME --private-dns-zone "$($env:MY_DNS_LABEL).private.mysql.database.azure.com" --tier Burstable --version 8.4 --vnet $env:MY_VNET_NAME --yes -o JSON
Write-Output "MySQL Flexible Server $env:MY_MYSQL_DB_NAME created"

# Get the current user's object ID for Key Vault permissions
$env:USER_OBJECT_ID = az ad signed-in-user show --query "id" -o tsv
Write-Output "User Object ID: $env:USER_OBJECT_ID"


# Create Log Analytics Workspace
$env:LOG_WORKSPACE_NAME = "mylogs$env:RANDOM_ID"
Write-Output "Creating Log Analytics Workspace: $env:LOG_WORKSPACE_NAME"
az monitor log-analytics workspace create `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
  --location $env:REGION
$env:LOG_WORKSPACE_ID = az monitor log-analytics workspace show `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --workspace-name $env:LOG_WORKSPACE_NAME `
  --query "id" -o tsv
Write-Output "Log Analytics Workspace ID: $env:LOG_WORKSPACE_ID"

# Create Azure Monitor Workspace (Prometheus)
$env:PROMETHEUS_NAME = "myprometheus$env:RANDOM_ID"
Write-Output "Creating Azure Monitor Workspace: $env:PROMETHEUS_NAME"
az monitor account create `
  --name $env:PROMETHEUS_NAME `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --location $env:REGION
$env:METRICS_WORKSPACE_ID = az monitor account show `
  --name $env:PROMETHEUS_NAME `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --query "id" -o tsv
Write-Output "Azure Monitor Workspace ID: $env:METRICS_WORKSPACE_ID"

# Create Container Registry
$env:ACR_NAME = "myregistry$env:RANDOM_ID"
Write-Output "Creating Azure Container Registry: $env:ACR_NAME"
az acr create `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --name $env:ACR_NAME `
  --sku Standard `
  --location $env:REGION `
  --admin-enabled false
$env:ACR_ID = az acr show `
  --name $env:ACR_NAME `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --query "id" -o tsv
$env:ACR_LOGIN_SERVER = az acr show `
  --name $env:ACR_NAME `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --query "loginServer" -o tsv
Write-Output "Container Registry: $env:ACR_LOGIN_SERVER"

# Create Application Insights
$env:APP_INSIGHTS_NAME = "myappinsights$env:RANDOM_ID"
Write-Output "Creating Application Insights: $env:APP_INSIGHTS_NAME"
az monitor app-insights component create `
  --app $env:APP_INSIGHTS_NAME `
  --location $env:REGION `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --workspace $env:LOG_WORKSPACE_ID
$env:APP_INSIGHTS_CONNECTION_STRING = az monitor app-insights component show `
  --app $env:APP_INSIGHTS_NAME `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --query "connectionString" -o tsv
Write-Output "Application Insights Connection String: $env:APP_INSIGHTS_CONNECTION_STRING"

# Create Key Vault with RBAC enabled
$env:KV_NAME = "ft-kv-$(Get-Random -Minimum 1000 -Maximum 9999)"
Write-Output "Creating Key Vault: $env:KV_NAME"
az keyvault create `
  --name $env:KV_NAME `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --location $env:REGION `
  --enable-rbac-authorization true `
  --sku standard
Write-Output "Azure Key Vault $env:KV_NAME created in resource group $env:MY_RESOURCE_GROUP_NAME"

# Get Key Vault ID
$env:KV_ID = az keyvault show `
  --name $env:KV_NAME `
  --query "id" -o tsv

  # Get Key Vault URI
$env:KV_URI = az keyvault show `
  --name $env:KV_NAME `
  --query "properties.vaultUri" -o tsv
Write-Output "Key Vault URI: $env:KV_URI"

# Create User Assigned Managed Identity
$env:IDENTITY_NAME = "myidentity$env:RANDOM_ID"
Write-Output "Creating Managed Identity: $env:IDENTITY_NAME"
az identity create `
  --name $env:IDENTITY_NAME `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --location $env:REGION
$env:IDENTITY_PRINCIPAL_ID = az identity show `
  --name $env:IDENTITY_NAME `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --query "principalId" -o tsv
$env:IDENTITY_CLIENT_ID_USER = az identity show `
  --name $env:IDENTITY_NAME `
  --resource-group $env:MY_RESOURCE_GROUP_NAME `
  --query "clientId" -o tsv
Write-Output "Managed Identity Principal ID: $env:IDENTITY_PRINCIPAL_ID"

# Wait for identity propagation
Write-Output "Waiting for identity propagation..."
Start-Sleep -Seconds 30

# Assign Key Vault Secrets User role to the managed identity
Write-Output "Assigning Key Vault Secrets User role to managed identity..."
az role assignment create `
  --role "Key Vault Secrets User" `
  --assignee $env:IDENTITY_PRINCIPAL_ID `
  --scope $env:KV_ID

# Assign Key Vault Certificate User role to the managed identity
Write-Output "Assigning Key Vault Certificate User role to managed identity..."
az role assignment create `
  --role "Key Vault Certificate User" `
  --assignee $env:IDENTITY_PRINCIPAL_ID `
  --scope $env:KV_ID

# Assign Key Vault Administrator role to the current user
Write-Output "Assigning Key Vault Administrator role to current user..."
az role assignment create `
  --role "Key Vault Administrator" `
  --assignee $env:USER_OBJECT_ID `
  --scope $env:KV_ID

# Setup AKS Cluster
Write-Output "AKS cluster name: $env:MY_AKS_CLUSTER_NAME"



$env:K8S_VERSION=$(az aks get-versions -l $env:REGION `
--query "values[?isDefault==``true``].version | [0]" `
-o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"

# create aks cluster
az aks create `
--resource-group $env:MY_RESOURCE_GROUP_NAME `
--name $env:MY_AKS_CLUSTER_NAME `
--location $env:REGION `
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
--enable-managed-identity `
--enable-workload-identity `
--enable-oidc-issuer `
--enable-acns `
--generate-ssh-keys
Write-Output "AKS Cluster $env:MY_AKS_CLUSTER_NAME created successfully in resource group $env:MY_RESOURCE_GROUP_NAME"

# Connect to the cluster
az aks get-credentials `
--resource-group $env:MY_RESOURCE_GROUP_NAME `
--name $env:MY_AKS_CLUSTER_NAME `
--overwrite-existing
Write-Output "Connected to AKS Cluster $env:MY_AKS_CLUSTER_NAME"

# add user nodepool
az aks nodepool add `
--resource-group $env:MY_RESOURCE_GROUP_NAME `
--cluster-name $env:MY_AKS_CLUSTER_NAME `
--mode User `
--name userpool `
--node-count 1
Write-Output "User nodepool added to AKS Cluster $env:MY_AKS_CLUSTER_NAME"

# Create a user assigned managed identity for the Azure Load Balancer Controller
$env:IDENTITY_RESOURCE_NAME = "azure-alb-identity"
$env:IDENTITY_RESOURCE_NAME='azure-alb-identity'
$env:mcResourceGroup=$(az aks show --resource-group $env:MY_RESOURCE_GROUP_NAME --name $env:MY_AKS_CLUSTER_NAME --query "nodeResourceGroup" -o tsv)
$env:mcResourceGroupId=$(az group show --name $env:mcResourceGroup --query id -otsv)
Write-Output "Creating identity $env:IDENTITY_RESOURCE_NAME in resource group $env:MY_RESOURCE_GROUP_NAME"

az identity create --resource-group $env:MY_RESOURCE_GROUP_NAME --name $env:IDENTITY_RESOURCE_NAME
$env:principalId="$(az identity show -g $env:MY_RESOURCE_GROUP_NAME -n $env:IDENTITY_RESOURCE_NAME --query principalId -otsv)"

Write-Output "Waiting 60 seconds to allow for replication of the identity..."
Start-Sleep -Seconds 60

Write-Output "Apply Reader role to the AKS managed cluster resource group for the newly provisioned identity"
az role assignment create --assignee-object-id $env:principalId --assignee-principal-type ServicePrincipal --scope $env:mcResourceGroupId --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" # Reader role

Write-Output "Set up federation with AKS OIDC issuer"
$env:AKS_OIDC_ISSUER = $(az aks show -n $env:MY_AKS_CLUSTER_NAME -g $env:MY_RESOURCE_GROUP_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv)

az identity federated-credential create --name "azure-alb-identity" `
    --identity-name $env:IDENTITY_RESOURCE_NAME `
    --resource-group $env:MY_RESOURCE_GROUP_NAME `
    --issuer $env:AKS_OIDC_ISSUER `
    --subject "system:serviceaccount:azure-alb-system:alb-controller-sa"
    
# install ALB Controller using helm

$env:HELM_NAMESPACE='agc-demo'
$env:CONTROLLER_NAMESPACE='azure-alb-system'
az aks get-credentials --resource-group $env:MY_RESOURCE_GROUP_NAME --name $env:MY_AKS_CLUSTER_NAME
helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller --namespace $env:HELM_NAMESPACE --version 1.8.12 --set albController.namespace=$env:CONTROLLER_NAMESPACE --set albController.podIdentity.clientID=$(az identity show -g $env:MY_RESOURCE_GROUP_NAME -n azure-alb-identity --query clientId -o tsv)

Write-Output "Azure Load Balancer Controller installed successfully in namespace $env:HELM_NAMESPACE"
# verify installation
kubectl get pods -n $env:CONTROLLER_NAMESPACE
kubectl get gatewayclass azure-alb-external -o yaml
Write-Output "Azure Load Balancer Controller verification completed."



# managed sceario subnet

$env:MC_RESOURCE_GROUP=$(az aks show --name $env:MY_AKS_CLUSTER_NAME --resource-group $env:MY_RESOURCE_GROUP_NAME --query "nodeResourceGroup" -o tsv)
$env:CLUSTER_SUBNET_ID=$(az vmss list --resource-group $env:MC_RESOURCE_GROUP --query '[0].virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id' -o tsv)

# Get VNet information
$vnetInfo = $(az network vnet show --ids $env:CLUSTER_SUBNET_ID --query '[name, resourceGroup, id]' -o tsv)
$vnetArray = $vnetInfo -split "`t"
$env:VNET_NAME = $vnetArray[0]
$env:VNET_RESOURCE_GROUP = $vnetArray[1]
$env:VNET_ID = $vnetArray[2]

Write-Output "Cluster VNet Name: $env:VNET_NAME"
Write-Output "Cluster VNet Resource Group: $env:VNET_RESOURCE_GROUP"
Write-Output "Cluster VNet ID: $env:VNET_ID"

#$env:SUBNET_ADDRESS_PREFIX='<network address and prefix for an address space under the vnet that has at least 250 available addresses (/24 or larger subnet)>'
$env:SUBNET_ADDRESS_PREFIX='10.225.0.0/24'
$env:ALB_SUBNET_NAME='subnet-alb' # subnet name can be any non-reserved subnet name (i.e. GatewaySubnet, AzureFirewallSubnet, AzureBastionSubnet would all be invalid)

az network vnet subnet create --resource-group $env:VNET_RESOURCE_GROUP `
    --vnet-name $env:VNET_NAME `
    --name $env:ALB_SUBNET_NAME `
    --address-prefixes $env:SUBNET_ADDRESS_PREFIX `
    --delegations 'Microsoft.ServiceNetworking/trafficControllers'

$env:ALB_SUBNET_ID=$(az network vnet subnet show --name $env:ALB_SUBNET_NAME `
 --resource-group $env:VNET_RESOURCE_GROUP `
 --vnet-name $env:VNET_NAME --query '[id]' `
 --output tsv)
 Write-Output "ALB Subnet ID: $env:ALB_SUBNET_ID"

 # delegate  permissions to managed identity
$env:IDENTITY_RESOURCE_NAME='azure-alb-identity'

$env:MC_RESOURCE_GROUP=$(az aks show --name $env:MY_AKS_CLUSTER_NAME `
 --resource-group $env:MY_RESOURCE_GROUP_NAME `
 --query "nodeResourceGroup" `
 -o tsv)

$env:mcResourceGroupId=$(az group show --name $env:MC_RESOURCE_GROUP --query id -o tsv)
$env:principalId=$(az identity show -g $env:MY_RESOURCE_GROUP_NAME -n $env:IDENTITY_RESOURCE_NAME --query principalId -o tsv)

# Delegate AppGw for Containers Configuration Manager role to AKS Managed Cluster RG
az role assignment create --assignee-object-id $env:principalId --assignee-principal-type ServicePrincipal --scope $env:mcResourceGroupId --role "fbc52c3f-28ad-4303-a892-8a056630b8f1" 
# Delegate Network Contributor permission for join to association subnet
az role assignment create --assignee-object-id $env:principalId --assignee-principal-type ServicePrincipal --scope $env:ALB_SUBNET_ID --role "4d97b98b-1d4f-4787-a291-c67834d212e7" 

# create namespace for alb
kubectl create namespace alb-test-infra
Write-Output "Namespace alb-test-infra created for Azure Load Balancer Controller."

@"
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: alb-test
  namespace: alb-test-infra
spec:
  associations:
  - $env:ALB_SUBNET_ID
"@ | kubectl apply -f -
Write-Output "Application Load Balancer resource 'alb-test' created in namespace 'alb-test-infra'."

# validate creation of the ALB
kubectl get applicationloadbalancer alb-test -n alb-test-infra -o yaml -w

# deploy sample app 
kubectl apply -f https://raw.githubusercontent.com/MicrosoftDocs/azure-docs/refs/heads/main/articles/application-gateway/for-containers/examples/traffic-split-scenario/deployment.yaml
Write-Output "Sample application deployed to demonstrate Azure Load Balancer Controller functionality."

# create gateway 
@"
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway-01
  namespace: test-infra
  annotations:
    alb.networking.azure.io/alb-namespace: alb-test-infra
    alb.networking.azure.io/alb-name: alb-test
spec:
  gatewayClassName: azure-alb-external
  listeners:
  - name: http-listener
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
"@ | kubectl apply -f -

kubectl get gateway gateway-01 -n test-infra -o yaml

Write-Output "Gateway resource 'gateway-01' created in namespace 'test-infra'."

#create two HTTPRoute resources for contoso.com and fabrikam.com domain names
@"
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: contoso-route
  namespace: test-infra
spec:
  parentRefs:
  - name: gateway-01
  hostnames:
  - "contoso.com"
  rules:
  - backendRefs:
    - name: backend-v1
      port: 8080
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: fabrikam-route
  namespace: test-infra
spec:
  parentRefs:
  - name: gateway-01
  hostnames:
  - "fabrikam.com"
  rules:
  - backendRefs:
    - name: backend-v2
      port: 8080
"@ | kubectl apply -f -
Write-Output "HTTPRoute resources 'contoso-route' and 'fabrikam-route' created in namespace 'test-infra'."
kubectl get httproute contoso-route -n test-infra -o yaml
kubectl get httproute fabrikam-route -n test-infra -o yaml

# test access to application 
$env:fqdn = $(kubectl get gateway gateway-01 -n test-infra -o jsonpath='{.status.addresses[0].value}')
Write-Output "Gateway FQDN: $env:fqdn"

$env:fqdnIp = (Resolve-DnsName $env:fqdn -Type A).IPAddress
Write-Output "Gateway IP: $env:fqdnIp"

# Test contoso.com
curl.exe -k --resolve "contoso.com:80:$env:fqdnIp" http://contoso.com

# Test fabrikam.com
curl.exe -k --resolve "fabrikam.com:80:$env:fqdnIp" http://fabrikam.com




# store resource names in .envrc file
@"
export NETWORK_PREFIX=$env:NETWORK_PREFIX
export RANDOM_ID=$env:RANDOM_ID
export MY_RESOURCE_GROUP_NAME=$env:MY_RESOURCE_GROUP_NAME
export MY_AKS_CLUSTER_NAME=$env:MY_AKS_CLUSTER_NAME
export MY_PUBLIC_IP_NAME=$env:MY_PUBLIC_IP_NAME
export MY_DNS_LABEL=$env:MY_DNS_LABEL
export MY_VNET_NAME=$env:MY_VNET_NAME
export MY_SN_NAME=$env:MY_SN_NAME
export MY_MYSQL_DB_NAME=$env:MY_MYSQL_DB_NAME
export MY_MYSQL_ADMIN_USERNAME=$env:MY_MYSQL_ADMIN_USERNAME
export MY_MYSQL_ADMIN_PW=$env:MY_MYSQL_ADMIN_PW
export MY_MYSQL_SN_NAME=$env:MY_MYSQL_SN_NAME
export MY_MYSQL_HOSTNAME=$env:MY_MYSQL_HOSTNAME
export MY_WP_ADMIN_PW=$env:MY_WP_ADMIN_PW
export MY_WP_ADMIN_USER=$env:MY_WP_ADMIN_USER
export FQDN=$env:FQDN
"@ | Out-File -FilePath ".envrc" -Encoding utf8
Write-Output ".envrc file created with resource names."