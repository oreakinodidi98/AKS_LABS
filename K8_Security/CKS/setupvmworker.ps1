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

# create vm
$env:VM_NAME = "myVM$RAND"
Write-Output "VM name: $env:VM_NAME"

az vm create --resource-group $env:RG_NAME --name $env:VM_NAME --image Canonical:ubuntu-24_04-lts:server:latest --admin-username azureuser --generate-ssh-keys

# Get the public IP address of the VM
$env:VM_IP = az network public-ip show --resource-group $env:RG_NAME --name "${env:VM_NAME}PublicIP" --query "ipAddress" -o tsv
Write-Output "VM IP address: $env:VM_IP"

# restrict acess with NSG
$env:MY_IP = (Invoke-WebRequest -Uri "http://ifconfig.me/ip").Content.Trim()
az network nsg rule create `
--resource-group $env:RG_NAME `
--nsg-name "${env:VM_NAME}NSG" `
--name "AllowMyIP" `
--priority 100 `
--access Allow `
--protocol Tcp `
--direction Inbound `
--source-address-prefixes $env:MY_IP `
--source-port-ranges "*" `
--destination-address-prefixes "*" `
--destination-port-ranges 22

# connect to vm
# common locations
$windowsKey = "$env:USERPROFILE\.ssh\id_rsa"
$wslKey = "~/.ssh/id_rsa"

# check existence
Test-Path $windowsKey; Test-Path $wslKey

# list .ssh files
Get-ChildItem "$env:USERPROFILE\.ssh" -Force
Write-Output "You can connect to the VM using: ssh azureuser@$env:VM_IP"
Write-Output "Make sure to use the private key located at: $env:USERPROFILE\.ssh\id_rsa"
Write-Output "Example command: ssh -i $env:USERPROFILE\.ssh\id_rsa azureuser@$env:VM_IP"
Write-Output "Remember to replace 'azureuser' with your actual username if different."
# Save the VM IP to a file for later use
Set-Content -Path ".\vm_ip.txt" -Value $env:VM_IP
Write-Output "VM IP address saved to vm_ip.txt"
# To connect to the VM, use the following command in your terminal


ssh -i "$env:USERPROFILE\.ssh\id_rsa" azureuser@$env:VM_IP

# or Bastion

# Get the VNet name and resource group
$vnetName = "myVM1027125805VNET"
$bastionSubnetName = "AzureBastionSubnet"  # Must be exactly this name

# Add Bastion subnet to existing VNet
az network vnet subnet create `
  --resource-group $env:RG_NAME `
  --vnet-name $vnetName `
  --name $bastionSubnetName `
  --address-prefixes "10.0.1.0/26"  # /26 minimum required

$bastionPipName = "bastion-pip"

az network public-ip create `
  --resource-group $env:RG_NAME `
  --name $bastionPipName `
  --sku Standard `
  --location $env:LOCATION

$bastionName = "myBastion"
az network bastion create `
  --resource-group $env:RG_NAME `
  --name $bastionName `
  --public-ip-address $bastionPipName `
  --vnet-name $vnetName `
  --location $env:LOCATION

Write-Output "Bastion deployment started. This takes about 10 minutes..."

# Wait for Bastion to be ready
az network bastion wait --resource-group $env:RG_NAME --name $bastionName --created

# Connect via CLI (requires Azure CLI 2.32+)
az network bastion ssh `
  --resource-group $env:RG_NAME `
  --name $bastionName `
  --target-resource-id "/subscriptions/cb5b077c-3ef5-4b2e-83e5-490cc5ca0e19/resourceGroups/$env:RG_NAME/providers/Microsoft.Compute/virtualMachines/$env:VM_NAME" `
  --auth-type ssh-key `
  --username azureuser `
  --ssh-key "$env:USERPROFILE\.ssh\id_rsa"

  # Monitor deployment progress
az network bastion show --resource-group $env:RG_NAME --name $bastionName --query "provisioningState" -o tsv

