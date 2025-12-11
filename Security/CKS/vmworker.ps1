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
$env:RG_NAME = "myresourcegroup$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# Create the resource group
az group create --name $env:RG_NAME --location $env:LOCATION

# Define VNet and subnet parameters for worker node
$env:VNET_NAME = "workerVNet$RAND"
$env:SUBNET_NAME = "workerSubnet"
$env:VM_NAME = "workerVM$RAND"
Write-Output "VM name: $env:VM_NAME"
Write-Output "VNet name: $env:VNET_NAME"

# Create VNet with different address space (172.16.0.0/16 instead of 10.0.0.0/16)
az network vnet create `
  --resource-group $env:RG_NAME `
  --name $env:VNET_NAME `
  --address-prefixes "172.16.0.0/16" `
  --subnet-name $env:SUBNET_NAME `
  --subnet-prefixes "172.16.1.0/24" `
  --location $env:LOCATION

Write-Output "Created VNet with address space 172.16.0.0/16"

az vm create --resource-group $env:RG_NAME --name $env:VM_NAME --image Canonical:ubuntu-24_04-lts:server:latest --admin-username azureuser --generate-ssh-keys --private-ip-address "172.16.1.10" --vnet-name $env:VNET_NAME --subnet $env:SUBNET_NAME

# Get the public IP address of the VM
$env:VM_IP = az network public-ip show --resource-group $env:RG_NAME --name "${env:VM_NAME}PublicIP" --query "ipAddress" -o tsv
Write-Output "VM IP address: $env:VM_IP"

# Get the private IP address of the VM
$env:VM_PRIVATE_IP = az vm show --resource-group $env:RG_NAME --name $env:VM_NAME --show-details --query "privateIps" -o tsv
Write-Output "VM Private IP address: $env:VM_PRIVATE_IP"

# restrict acess with NSG
$env:MY_IP = (Invoke-WebRequest -Uri "http://ifconfig.me/ip").Content.Trim()
az network nsg rule create `
--resource-group $env:RG_NAME `
--nsg-name "${env:VM_NAME}NSG" `
--name "AllowMyIP-SSH" `
--priority 100 `
--access Allow `
--protocol Tcp `
--direction Inbound `
--source-address-prefixes $env:MY_IP `
--source-port-ranges "*" `
--destination-address-prefixes "*" `
--destination-port-ranges 22

# Allow SSH on port 443 (alternative)
az network nsg rule create `
  --resource-group $env:RG_NAME `
  --nsg-name "${env:VM_NAME}NSG" `
  --name "AllowMyIP-SSH-443" `
  --priority 110 `
  --access Allow `
  --protocol Tcp `
  --direction Inbound `
  --source-address-prefixes $env:MY_IP `
  --source-port-ranges "*" `
  --destination-address-prefixes "*" `
  --destination-port-ranges 443

# Allow Kubernetes API traffic from master node VNet (10.0.0.0/16)
az network nsg rule create `
  --resource-group $env:RG_NAME `
  --nsg-name "${env:VM_NAME}NSG" `
  --name "AllowK8sFromMaster" `
  --priority 200 `
  --access Allow `
  --protocol "*" `
  --direction Inbound `
  --source-address-prefixes "10.0.0.0/16" `
  --source-port-ranges "*" `
  --destination-address-prefixes "*" `
  --destination-port-ranges "22,443,6443,10250,10256,30000-32767"

# Allow Kubernetes API traffic from master node VNet - separate rules for each port/range
# SSH from master
az network nsg rule create `
  --resource-group $env:RG_NAME `
  --nsg-name "${env:VM_NAME}NSG" `
  --name "AllowK8s-SSH-FromMaster" `
  --priority 200 `
  --access Allow `
  --protocol Tcp `
  --direction Inbound `
  --source-address-prefixes "10.0.0.0/16" `
  --source-port-ranges "*" `
  --destination-address-prefixes "*" `
  --destination-port-ranges 22

# SSH on 443 from master
az network nsg rule create `
  --resource-group $env:RG_NAME `
  --nsg-name "${env:VM_NAME}NSG" `
  --name "AllowK8s-SSH443-FromMaster" `
  --priority 201 `
  --access Allow `
  --protocol Tcp `
  --direction Inbound `
  --source-address-prefixes "10.0.0.0/16" `
  --source-port-ranges "*" `
  --destination-address-prefixes "*" `
  --destination-port-ranges 443

# Kubernetes API server from master
az network nsg rule create `
  --resource-group $env:RG_NAME `
  --nsg-name "${env:VM_NAME}NSG" `
  --name "AllowK8s-API-FromMaster" `
  --priority 202 `
  --access Allow `
  --protocol Tcp `
  --direction Inbound `
  --source-address-prefixes "10.0.0.0/16" `
  --source-port-ranges "*" `
  --destination-address-prefixes "*" `
  --destination-port-ranges 6443

# Kubelet API from master
az network nsg rule create `
  --resource-group $env:RG_NAME `
  --nsg-name "${env:VM_NAME}NSG" `
  --name "AllowK8s-Kubelet-FromMaster" `
  --priority 203 `
  --access Allow `
  --protocol Tcp `
  --direction Inbound `
  --source-address-prefixes "10.0.0.0/16" `
  --source-port-ranges "*" `
  --destination-address-prefixes "*" `
  --destination-port-ranges 10250

# kube-proxy from master
az network nsg rule create `
  --resource-group $env:RG_NAME `
  --nsg-name "${env:VM_NAME}NSG" `
  --name "AllowK8s-KubeProxy-FromMaster" `
  --priority 204 `
  --access Allow `
  --protocol Tcp `
  --direction Inbound `
  --source-address-prefixes "10.0.0.0/16" `
  --source-port-ranges "*" `
  --destination-address-prefixes "*" `
  --destination-port-ranges 10256

# NodePort services from master
az network nsg rule create `
  --resource-group $env:RG_NAME `
  --nsg-name "${env:VM_NAME}NSG" `
  --name "AllowK8s-NodePort-FromMaster" `
  --priority 205 `
  --access Allow `
  --protocol Tcp `
  --direction Inbound `
  --source-address-prefixes "10.0.0.0/16" `
  --source-port-ranges "*" `
  --destination-address-prefixes "*" `
  --destination-port-ranges "30000-32767"


# Save connection information
Write-Output "You can connect to the VM using: ssh azureuser@$env:VM_IP"
Write-Output "Make sure to use the private key located at: $env:USERPROFILE\.ssh\id_rsa"
Write-Output "Example command: ssh -i $env:USERPROFILE\.ssh\id_rsa azureuser@$env:VM_IP"

# Save the VM information to files for later use
Set-Content -Path ".\worker_vm_public_ip.txt" -Value $env:VM_IP
Set-Content -Path ".\worker_vm_private_ip.txt" -Value $env:VM_PRIVATE_IP
Set-Content -Path ".\worker_vnet_name.txt" -Value $env:VNET_NAME
Set-Content -Path ".\worker_rg_name.txt" -Value $env:RG_NAME

Write-Output "Worker VM information saved to files:"
Write-Output "- Public IP: worker_vm_public_ip.txt"
Write-Output "- Private IP: worker_vm_private_ip.txt"
Write-Output "- VNet Name: worker_vnet_name.txt"
Write-Output "- Resource Group: worker_rg_name.txt"

Write-Output ""
Write-Output "Next steps:"
Write-Output "1. SSH to the worker VM: ssh -i `"$env:USERPROFILE\.ssh\id_rsa`" azureuser@$env:VM_IP"
Write-Output "2. Install Kubernetes on the worker VM"
Write-Output "3. Create VNet peering between master (10.0.0.0/16) and worker (172.16.0.0/16) VNets"
Write-Output "4. Join the worker to the cluster using the master's private IP (10.0.0.4)"

