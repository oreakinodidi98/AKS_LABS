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
$env:RG_NAME = "prometheuslab$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# CREATE THE RESOURCE GROUP FIRST!
az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:RG_NAME created"

# Setup AKS Cluster and VNet for a 2-VM + AKS lab
$env:AKS_NAME = "myakscluster$RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"

# Shared VNet for the two Linux VMs and the AKS cluster so they can talk to each other.
$env:vnet = "prometheus-vnet"
$env:vmSubnet = "vm-subnet"
$env:aksSubnet = "aks-subnet"
$env:nsgName = "vm-nsg"
$env:myIp = (Invoke-RestMethod -Uri "https://api.ipify.org")
Write-Output "Current public IP: $env:myIp"
$env:vm1Name = "prometheus-vm-01"
$env:vm2Name = "monitored-vm-01"
$env:adminUser = "azureuser"

# Get the latest Kubernetes version available in the region
$env:K8S_VERSION = $(az aks get-versions -l $env:LOCATION --query "values[?isDefault==``true``].version | [0]" -o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"

# Create one VNet with a VM subnet and an AKS subnet. This is the required networking for the lab.
az network vnet create -g $env:RG_NAME -n $env:vnet -l $env:LOCATION --address-prefixes 10.50.0.0/16 `
  --subnet-name $env:vmSubnet --subnet-prefixes 10.50.1.0/24
Write-Output "VNet and VM subnet created."

az network vnet subnet create -g $env:RG_NAME --vnet-name $env:vnet -n $env:aksSubnet `
  --address-prefixes 10.50.2.0/24
Write-Output "AKS subnet created in the same VNet."

# One NSG on the VM subnet is enough. Avoid the duplicate subnet + NIC NSG rules.
az network nsg create -g $env:RG_NAME -n $env:nsgName -l $env:LOCATION
Write-Output "NSG created for the VM subnet."

az network nsg rule create --resource-group $env:RG_NAME --nsg-name $env:nsgName --name allow-ssh-from-me --priority 102 `
  --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "$($env:myIp)/32" --source-port-ranges "*" `
  --destination-address-prefixes "*" --destination-port-ranges 22

az network nsg rule create --resource-group $env:RG_NAME --nsg-name $env:nsgName --name allow-vnet-inbound --priority 110 `
  --direction Inbound --access Allow --protocol "*" --source-address-prefixes "10.50.0.0/16" --source-port-ranges "*" `
  --destination-address-prefixes "10.50.0.0/16" --destination-port-ranges "*"

az network nsg rule create --resource-group $env:RG_NAME --nsg-name $env:nsgName --name allow-node-exporter --priority 120 `
  --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "10.50.0.0/16" --source-port-ranges "*" `
  --destination-address-prefixes "*" --destination-port-ranges 9100

az network nsg rule create `
  --resource-group $env:RG_NAME `
  --nsg-name $env:nsgName `
  --name allow-prometheus `
  --priority 130 `
  --direction Inbound `
  --access Allow `
  --protocol Tcp `
  --source-address-prefixes "*" `
  --destination-port-ranges 9090

az network vnet subnet update -g $env:RG_NAME --vnet-name $env:vnet -n $env:vmSubnet --network-security-group $env:nsgName
Write-Output "NSG applied to the VM subnet."

# Create the two Linux VMs in the same VNet so they can reach each other and the AKS cluster.
az vm create -g $env:RG_NAME -n $env:vm1Name -l $env:LOCATION `
  --image Ubuntu2204 --size Standard_D2s_v5 --admin-username $env:adminUser `
  --generate-ssh-keys --vnet-name $env:vnet --subnet $env:vmSubnet `
  --public-ip-sku Standard --assign-identity
Write-Output "VM1 created for Prometheus."

az vm create -g $env:RG_NAME -n $env:vm2Name -l $env:LOCATION `
  --image Ubuntu2204 --size Standard_D2s_v5 --admin-username $env:adminUser `
  --generate-ssh-keys --vnet-name $env:vnet --subnet $env:vmSubnet `
  --public-ip-sku Standard
Write-Output "VM2 created as the monitored Linux target."

$env:AKS_SUBNET_ID = az network vnet subnet show -g $env:RG_NAME --vnet-name $env:vnet --name $env:aksSubnet --query "id" -o tsv
Write-Output "AKS subnet ID: $env:AKS_SUBNET_ID"

$env:aksIdentityName = "aks-mi-$RAND"
write-Output "Creating managed identity for AKS: $env:aksIdentityName"
az identity create `
  --resource-group $env:RG_NAME `
  --name $env:aksIdentityName `
  --location $env:LOCATION
write-Output "Managed identity for AKS created."
$env:AKS_IDENTITY_ID = az identity show `
  --resource-group $env:RG_NAME `
  --name $env:aksIdentityName `
  --query id -o tsv
write-Output "AKS managed identity ID: $env:AKS_IDENTITY_ID"

# Create AKS automatic in the same VNet so the cluster can talk to the VMs over 10.50.0.0/16.
az aks create `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --location $env:LOCATION `
  --kubernetes-version $env:K8S_VERSION `
  --node-count 1 `
  --network-plugin azure `
  --vnet-subnet-id $env:AKS_SUBNET_ID `
  --assign-identity $env:AKS_IDENTITY_ID
Write-Output "AKS Cluster $env:AKS_NAME created successfully in the same VNet." 

# Set kubeconfig path and connect to the cluster
$env:aksKubeConfigPath = "$env:USERPROFILE\.kube\config"
az aks get-credentials --resource-group $env:RG_NAME --name $env:AKS_NAME --file $env:aksKubeConfigPath --overwrite-existing
Write-Output "Connected to AKS Cluster $env:AKS_NAME"

$env:KUBECONFIG = $env:aksKubeConfigPath
Write-Output "KUBECONFIG environment variable set to: $env:KUBECONFIG"

$env:KUBELET_OBJECT_ID = $(az aks show --name $env:AKS_NAME --resource-group $env:RG_NAME --query identityProfile.kubeletidentity.objectId --output tsv)
Write-Output "KUBELET_OBJECT_ID: $env:KUBELET_OBJECT_ID"

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

# Get VM public IPs and prepare the final lab access steps.
$env:vm1PublicIp = az vm show -g $env:RG_NAME -n $env:vm1Name -d --query publicIps -o tsv
$env:vm2PublicIp = az vm show -g $env:RG_NAME -n $env:vm2Name -d --query publicIps -o tsv

Write-Output "VM1 public IP: $env:vm1PublicIp"
Write-Output "VM2 public IP: $env:vm2PublicIp"
Write-Output "SSH to VM1: ssh -i $HOME\.ssh\id_rsa $env:adminUser@$env:vm1PublicIp"
Write-Output "SSH to VM2: ssh -i $HOME\.ssh\id_rsa $env:adminUser@$env:vm2PublicIp"
Write-Output "On VM2, install node_exporter: sudo apt-get update && sudo apt-get install -y prometheus-node-exporter && sudo systemctl enable --now prometheus-node-exporter"
Write-Output "On VM1, install Prometheus and configure the VM2 target at port 9100."

# store resource names in .envrc file
@"
export RAND=$env:RAND
export LOCATION=$env:LOCATION
export RG_NAME=$env:RG_NAME
export VNET_NAME=$env:vnet
export VM_SUBNET_NAME=$env:vmSubnet
export AKS_SUBNET_NAME=$env:aksSubnet
export VM1_NAME=$env:vm1Name
export VM2_NAME=$env:vm2Name
export VM1_PUBLIC_IP=$env:vm1PublicIp
export VM2_PUBLIC_IP=$env:vm2PublicIp
export AKS_NAME=$env:AKS_NAME
export K8S_VERSION=$env:K8S_VERSION
export aksKubeConfigPath=$env:aksKubeConfigPath
export ACR_NAME=$env:ACR_NAME
export ACR_ID=$env:ACR_ID
export ACR_LOGIN_SERVER=$env:ACR_LOGIN_SERVER
export KUBELET_OBJECT_ID=$env:KUBELET_OBJECT_ID
ssh -i "$HOME\.ssh\prometheus-lab" azureuser@4.225.174.238
ssh -i "$HOME\.ssh\prometheus-lab" azureuser@20.240.133.84
"@ | Out-File -FilePath ".envrc" -Encoding utf8
Write-Output ".envrc file created with resource names."