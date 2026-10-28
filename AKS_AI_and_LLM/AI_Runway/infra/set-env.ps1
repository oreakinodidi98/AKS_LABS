# set-env.ps1
# Required environment variables: ARM_CLIENT_SECRET and TF_VAR_admin_password.
$env:ARM_SUBSCRIPTION_ID = "f76acfa2-f79b-465f-a4ef-4cd279b35d4d"
$env:ARM_TENANT_ID = "2b903add-c8cb-4ad4-8eb4-6c3a6504b5bf"
$env:ARM_CLIENT_ID = "7ae376f8-2304-4eba-b2b9-29cb7d2d9d1e"
if ([string]::IsNullOrWhiteSpace($env:ARM_CLIENT_SECRET)) {
    throw "Set ARM_CLIENT_SECRET in your environment before running this script; do not save credentials in source control."
}

# VM Admin Password (must have: lowercase, uppercase, digit, special char)
if ([string]::IsNullOrWhiteSpace($env:TF_VAR_admin_password)) {
    throw "Set TF_VAR_admin_password in your environment before running this script; use a strong VM admin password."
}

# Generate a random number
$RAND = Get-Random
# Set it as an environment variable
$env:RAND = $RAND
# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"
# Set Location
$env:LOCATION = "swedencentral"
Write-Output "Location set to: $env:LOCATION"
$env:sa = "tfstorage1744947267"
$env:rg = "myresourcegroup1744947267"
$env:vnet = "tfstate-vnet"
$env:peSubnet = "private-endpoints"
$env:vmSubnet = "tools"
$env:nsgName = "$($env:vmSubnet)-nsg"
$env:dnsZone = "privatelink.blob.core.windows.net"
$env:peName = "pe-tfstate-blob"
$env:myIp = (Invoke-RestMethod -Uri "https://api.ipify.org")
Write-Host "IP is: $env:myIp"
$env:vmName = "tf-jumpbox-01"
$env:adminUser = "azureuser"

az network vnet create -g $env:rg -n $env:vnet -l $env:LOCATION --address-prefixes 10.50.0.0/16 `
  --subnet-name $env:vmSubnet --subnet-prefixes 10.50.1.0/24
Write-Output "Virtual network and tools subnet created."

az network vnet subnet create -g $env:rg --vnet-name $env:vnet -n $env:peSubnet `
  --address-prefixes 10.50.2.0/24 --disable-private-endpoint-network-policies true
Write-Output "Private endpoints subnet created."

# Explicit NSG for jumpbox subnet.
az network nsg create -g $env:rg -n $env:nsgName -l $env:LOCATION
az network vnet subnet update -g $env:rg --vnet-name $env:vnet -n $env:vmSubnet --network-security-group $env:nsgName
Write-Output "NSG created and attached to tools subnet."

# Private DNS zone + VNet link
az network private-dns zone create -g $env:rg -n $env:dnsZone
Write-Output "Private DNS zone created."
az network private-dns link vnet create -g $env:rg -n "link-$env:vnet" `
  -z $env:dnsZone -v $env:vnet --registration-enabled false
Write-Output "Private DNS zone linked to VNet."

# Private endpoint for Blob
$saId = az storage account show -g $env:rg -n $env:sa --query id -o tsv
Write-Output "Storage account ID: $saId"
az network private-endpoint create -g $env:rg -n $env:peName -l $env:LOCATION `
  --vnet-name $env:vnet --subnet $env:peSubnet `
  --private-connection-resource-id $saId --group-id blob --connection-name "conn-$env:peName"
Write-Output "Private endpoint for Blob created."

# Attach DNS zone group to PE
az network private-endpoint dns-zone-group create -g $env:rg `
  --endpoint-name $env:peName -n "blob-zone-group" `
  --private-dns-zone $env:dnsZone --zone-name "blob"
Write-Output "DNS zone group attached to private endpoint."

az feature register --name AllowBringYourOwnPublicIpAddress --namespace Microsoft.Network
# Register all providers needed by Terraform (skip_provider_registration=true means Terraform won't auto-register)
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Monitor
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.StorageCache
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.ManagedIdentity
az provider register --namespace Microsoft.Insights
Write-Output "All required providers registered."
az feature show --name AllowBringYourOwnPublicIpAddress --namespace Microsoft.Network --query properties.state -o tsv

# jumpbox VM with public IP (quick path)
az vm create -g $env:rg -n $env:vmName -l $env:LOCATION `
  --image Ubuntu2204 --size Standard_D2s_v5 --admin-username $env:adminUser `
  --generate-ssh-keys --vnet-name $env:vnet `
  --subnet $env:vmSubnet --public-ip-sku Standard `
  --assign-identity
Write-Output "Jumpbox VM created with public IP and managed identity."

# Allow SSH only from your current IP
az network nsg rule create --resource-group $env:rg --nsg-name $env:nsgName --name allow-ssh-from-me --priority 100 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "$($env:myIp)/32" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges 22
Write-Output "NSG rule created to allow SSH only from your current IP: $env:myIp"

# NIC NSG rule to override Defender JIT deny and allow SSH from current IP.
$env:vmNicId = az vm show --resource-group $env:rg --name $env:vmName --query "networkProfile.networkInterfaces[0].id" -o tsv
$env:vmNicNsgId = az network nic show --ids $env:vmNicId --query "networkSecurityGroup.id" -o tsv
$env:vmNicNsgName = ($env:vmNicNsgId -split "/")[-1]
az network nsg rule create --resource-group $env:rg --nsg-name $env:vmNicNsgName --name allow-ssh-current-ip --priority 200 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "$($env:myIp)/32" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges 22
Write-Output "NIC NSG rule created: allow-ssh-current-ip on $env:vmNicNsgName for $env:myIp/32"

# Give VM managed identity storage data-plane access to tfstate storage account
$env:vmPrincipalId = az vm show --resource-group $env:rg --name $env:vmName --query "identity.principalId" -o tsv
Write-Output "VM managed identity principal ID: $env:vmPrincipalId"
$env:saId = az storage account show --resource-group $env:rg --name $env:sa --query "id" -o tsv
Write-Output "Storage account ID: $env:saId"
az role assignment create --assignee-object-id $env:vmPrincipalId --assignee-principal-type ServicePrincipal --role "Storage Blob Data Contributor" --scope $env:saId
Write-Output "Role assignment created: VM managed identity has Storage Blob Data Contributor access to the storage account."

# Assign Contributor at subscription scope so the identity can create resources via Terraform
az role assignment create --assignee-object-id $env:vmPrincipalId --assignee-principal-type ServicePrincipal --role "Contributor" --scope "/subscriptions/$env:ARM_SUBSCRIPTION_ID"
Write-Output "Role assignment created: VM managed identity has Contributor access at subscription scope."
# Fix role assignment write permission (Contributor alone can't assign roles)
az role assignment create `
  --assignee-object-id 31f8a85b-69ba-4329-951a-9cf99332c122 `
  --assignee-principal-type ServicePrincipal `
  --role "User Access Administrator" `
  --scope "/subscriptions/f76acfa2-f79b-465f-a4ef-4cd279b35d4d"


#Get VM public IP and SSH in
$env:vmPublicIp = az vm show -g $env:rg -n $env:vmName -d --query publicIps -o tsv
Write-Output "VM public IP: $env:vmPublicIp"
ssh $env:adminUser@$env:vmPublicIp
Write-Output " Run the following in the VM
ssh -i $HOME\.ssh\id_rsa azureuser@$env:vmPublicIp
nslookup tfstorage1744947267.blob.core.windows.net
az version || curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login --identity
az account show
az storage container list --account-name tfstorage1744947267 --auth-mode login -o table
git --version || sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/oreakinodidi98/AKS_LABS.git
cd AKS_LABS/AKS_AI_and_LLM/AI_Runway/infra
terraform version || (
  sudo apt-get update &&
  sudo apt-get install -y unzip wget &&
  wget -q https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip &&
  unzip terraform_1.9.8_linux_amd64.zip &&
  sudo mv terraform /usr/local/bin/terraform
)
terraform version
env | grep '^ARM_'

unset ARM_CLIENT_ID
unset ARM_CLIENT_SECRET
unset ARM_CLIENT_CERTIFICATE_PATH
unset ARM_CLIENT_CERTIFICATE_PASSWORD
unset ARM_OIDC_TOKEN
unset ARM_USE_OIDC
unset ARM_USE_AKS_WORKLOAD_IDENTITY

export ARM_USE_MSI=true
export ARM_USE_CLI=false
export ARM_SUBSCRIPTION_ID=f76acfa2-f79b-465f-a4ef-4cd279b35d4d
export ARM_TENANT_ID=2b903add-c8cb-4ad4-8eb4-6c3a6504b5bf

terraform init -reconfigure
terraform validate
terraform plan


terraform plan  -var="enable_gpu_inference_pool=false"

When quota is approved later: export TF_VAR_enable_gpu_inference_pool=true
terraform apply -var="enable_gpu_inference_pool=false" --auto-approve
terraform apply 

# 1) Port-forward Argo CD API server
kubectl -n argocd port-forward svc/argo-cd-argocd-server 8080:443

# 2) Get initial admin password
ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# 3) Login
argocd login localhost:8080 --username admin --password "$ARGO_PWD" --insecure

# 4) Sync and check status
argocd app sync airunway
argocd app get airunway
"