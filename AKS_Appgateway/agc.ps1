# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND

# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"

# Register required resource providers on Azure.
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.NetworkFunction
az provider register --namespace Microsoft.ServiceNetworking
Write-Output "Required resource providers registered."

# Install Azure CLI extensions.
az extension add --name alb
Write-Output "Azure CLI extensions installed."
# Set Location
$env:LOCATION = "uksouth"
Write-Output "Location set to: $env:LOCATION"

# Create a resource group name using the random number
$env:RG_NAME = "myresourcegroup$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# CREATE THE RESOURCE GROUP FIRST!
az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:RG_NAME created"

# Setup AKS Cluster
$env:AKS_NAME = "myakscluster$RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"

# Get the latest Kubernetes version available in the region
#env:K8S_VERSION=$(az aks get-versions -l $env:LOCATION --query "orchestrators[?default==\`$true\`].orchestratorVersion | [0]" -o tsv)

$env:K8S_VERSION=$(az aks get-versions -l $env:LOCATION `
--query "values[?isDefault==``true``].version | [0]" `
-o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"

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
--enable-managed-identity `
--enable-workload-identity `
--enable-oidc-issuer `
--enable-acns `
--generate-ssh-keys
Write-Output "AKS Cluster $env:AKS_NAME created successfully in resource group $env:RG_NAME"

# Connect to the cluster
az aks get-credentials `
--resource-group $env:RG_NAME `
--name $env:AKS_NAME `
--overwrite-existing
Write-Output "Connected to AKS Cluster $env:AKS_NAME"

# add user nodepool
az aks nodepool add `
--resource-group $env:RG_NAME `
--cluster-name $env:AKS_NAME `
--mode User `
--name userpool `
--node-count 1
Write-Output "User nodepool added to AKS Cluster $env:AKS_NAME"

# Create a user assigned managed identity for the Azure Load Balancer Controller
$env:RG_NAME = "myresourcegroup1299770908"
$env:AKS_NAME = "myakscluster1299770908"
$env:IDENTITY_RESOURCE_NAME = "azure-alb-identity"
$env:IDENTITY_RESOURCE_NAME='azure-alb-identity'
$env:mcResourceGroup=$(az aks show --resource-group $env:RG_NAME --name $env:AKS_NAME --query "nodeResourceGroup" -o tsv)
$env:mcResourceGroupId=$(az group show --name $env:mcResourceGroup --query id -otsv)
Write-Output "Creating identity $env:IDENTITY_RESOURCE_NAME in resource group $env:RG_NAME"

az identity create --resource-group $env:RG_NAME --name $env:IDENTITY_RESOURCE_NAME
$env:principalId="$(az identity show -g $env:RG_NAME -n $env:IDENTITY_RESOURCE_NAME --query principalId -otsv)"

Write-Output "Waiting 60 seconds to allow for replication of the identity..."
Start-Sleep -Seconds 60

Write-Output "Apply Reader role to the AKS managed cluster resource group for the newly provisioned identity"
az role assignment create --assignee-object-id $env:principalId --assignee-principal-type ServicePrincipal --scope $env:mcResourceGroupId --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" # Reader role

Write-Output "Set up federation with AKS OIDC issuer"
$env:AKS_OIDC_ISSUER = $(az aks show -n $env:AKS_NAME -g $env:RG_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv)

az identity federated-credential create --name "azure-alb-identity" `
    --identity-name $env:IDENTITY_RESOURCE_NAME `
    --resource-group $env:RG_NAME `
    --issuer $env:AKS_OIDC_ISSUER `
    --subject "system:serviceaccount:azure-alb-system:alb-controller-sa"

# install ALB Controller using helm

$env:HELM_NAMESPACE='agc-demo'
$env:CONTROLLER_NAMESPACE='azure-alb-system'
az aks get-credentials --resource-group $env:RG_NAME --name $env:AKS_NAME
helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller --namespace $env:HELM_NAMESPACE --version 1.8.12 --set albController.namespace=$env:CONTROLLER_NAMESPACE --set albController.podIdentity.clientID=$(az identity show -g $env:RG_NAME -n azure-alb-identity --query clientId -o tsv)

Write-Output "Azure Load Balancer Controller installed successfully in namespace $env:HELM_NAMESPACE"
# verify installation
kubectl get pods -n $env:CONTROLLER_NAMESPACE
kubectl get gatewayclass azure-alb-external -o yaml
Write-Output "Azure Load Balancer Controller verification completed."

# to delete use the following:
# helm uninstall alb-controller
# kubectl delete ns azure-alb-system
# kubectl delete gatewayclass azure-alb-external

# managed sceario subnet

$env:MC_RESOURCE_GROUP=$(az aks show --name $env:AKS_NAME --resource-group $env:RG_NAME --query "nodeResourceGroup" -o tsv)
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

$env:MC_RESOURCE_GROUP=$(az aks show --name $env:AKS_NAME `
 --resource-group $env:RG_NAME `
 --query "nodeResourceGroup" `
 -o tsv)

$env:mcResourceGroupId=$(az group show --name $env:MC_RESOURCE_GROUP --query id -o tsv)
$env:principalId=$(az identity show -g $env:RG_NAME -n $env:IDENTITY_RESOURCE_NAME --query principalId -o tsv)

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

