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
$env:RG_NAME = "aroresourcegroup$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# set cluster name
$env:CLUSTER_NAME = "AROCluster$RAND"
$env:CLUSTER_VERSION = "4.15.35"
Write-Output "Cluster name: $env:CLUSTER_NAME"

# Create the resource group
az group create --name $env:RG_NAME --location $env:LOCATION

# Register the Microsoft.RedHatOpenShift resource provider
az provider register -n Microsoft.RedHatOpenShift --wait

# Register the Microsoft.Compute resource provide
az provider register -n Microsoft.Compute --wait

# Register the Microsoft.Authorization resource provide
az provider register -n Microsoft.Authorization --wait

# Register the Microsoft.Storage resource provide
az provider register -n Microsoft.Storage --wait

Write-Output "All providers registered successfully."

# pause for a few seconds to allow time for registration to complete
Start-Sleep -Seconds 30

# check AZcli
$azVersion = az --version
Write-Output "AZ CLI Version: $azVersion"

# create Virtual network
$env:VNET_NAME = "aroVNet$RAND"
$env:SUBNET_NAME = "aroSubnet$RAND"
Write-Output "VNet name: $env:VNET_NAME"
Write-Output "Subnet name: $env:SUBNET_NAME"
az network vnet create --resource-group $env:RG_NAME --name $env:VNET_NAME --address-prefix 10.0.0.0/22

# create empty subnet for master nodes
az network vnet subnet create --resource-group $env:RG_NAME --vnet-name $env:VNET_NAME --name "master-subnet" --address-prefixes 10.0.0.0/23

# create subnet for worker nodes
az network vnet subnet create --resource-group $env:RG_NAME --vnet-name $env:VNET_NAME --name "worker-subnet" --address-prefixes 10.0.2.0/23

#Disable subnet private endpoint policies on the master subnet. This is required to be able to connect and manage the cluster.
az network vnet subnet update --resource-group $env:RG_NAME --vnet-name $env:VNET_NAME --name "master-subnet" --disable-private-endpoint-network-policies true

Write-Output " need to Obtain your pull secret by navigating to https://cloud.redhat.com/openshift/install/azure/aro-provisioned and clicking Download pull secret. Run the following command to create a cluster. When running the az aro create command, you can reference your pull secret using the –pull-secret @pull-secret.txt parameter. Execute az aro create from the directory where you stored your pull-secret.txt file. Otherwise, replace @pull-secret.txt with @<path-to-my-pull-secret-file>."
# instal Aro  preview extension
az extension add --name aro --upgrade
Write-Output "ARO extension installed successfully."

# create ARO cluster
az aro create --resource-group $env:RG_NAME --name $env:CLUSTER_NAME --vnet $env:VNET_NAME --master-subnet "master-subnet" --worker-subnet "worker-subnet" --location $env:LOCATION --pull-secret @pull-secret.txt --cluster-resource-group "${env:RG_NAME}-cluster" --version 4.17.27