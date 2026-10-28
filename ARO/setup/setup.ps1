# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND

# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"

# Set Location
$env:AZR_RESOURCE_LOCATION = "uksouth"
Write-Output "Location set to: $env:AZR_RESOURCE_LOCATION"

# login to az cli
az login

# check quota for ARO clusters
az vm list-usage --location $env:AZR_RESOURCE_LOCATION -o table
Write-Output "Please ensure you have sufficient quota for the following resources in the $env:AZR_RESOURCE_LOCATION region"

# register the ARO resource provider
az provider register -n Microsoft.RedHatOpenShift --wait
az provider register -n Microsoft.Compute --wait
az provider register -n Microsoft.Storage --wait
az provider register -n Microsoft.Authorization --wait

Write-Output "Log into https://console.redhat.com
Browse to https://console.redhat.com/openshift/install/azure/aro-provisioned
click the Download pull secret button and remember where you saved it, you’ll reference it later.
"

# Create variable names using the random number
$env:AZR_RESOURCE_GROUP = "rg-openshift$RAND"
Write-Output "Resource group name: $env:AZR_RESOURCE_GROUP"
$env:AZR_CLUSTER= "cluster$RAND"
Write-Output "Cluster name: $env:AZR_CLUSTER"
$env:AZR_PULL_SECRET=~/Downloads/pull-secret.txt
Write-Output "Pull secret file path: $env:AZR_PULL_SECRET"

# Create a resource group
az group create `
  --name $env:AZR_RESOURCE_GROUP `
  --location $env:AZR_RESOURCE_LOCATION
Write-Output "Resource group $env:AZR_RESOURCE_GROUP created"

# create Networking
az network vnet create `
  --address-prefixes 10.0.0.0/22 `
  --name "$env:AZR_CLUSTER-aro-vnet-$env:AZR_RESOURCE_LOCATION" `
  --resource-group $env:AZR_RESOURCE_GROUP
Write-Output "Virtual network $env:AZR_CLUSTER-aro-vnet-$env:AZR_RESOURCE_LOCATION created"

az network vnet subnet create `
  --resource-group $env:AZR_RESOURCE_GROUP `
  --vnet-name "$env:AZR_CLUSTER-aro-vnet-$env:AZR_RESOURCE_LOCATION" `
  --name "$env:AZR_CLUSTER-aro-control-subnet-$env:AZR_RESOURCE_LOCATION" `
  --address-prefixes 10.0.0.0/23
Write-Output "Controll plane Subnet $env:AZR_CLUSTER-aro-control-subnet-$env:AZR_RESOURCE_LOCATION created"

az network vnet subnet create `
  --resource-group $env:AZR_RESOURCE_GROUP `
  --vnet-name "$env:AZR_CLUSTER-aro-vnet-$env:AZR_RESOURCE_LOCATION" `
  --name "$env:AZR_CLUSTER-aro-machine-subnet-$env:AZR_RESOURCE_LOCATION" `
  --address-prefixes 10.0.2.0/23
Write-Output "Machine Subnet $env:AZR_CLUSTER-aro-machine-subnet-$env:AZR_RESOURCE_LOCATION created"

# Disable network policies for Private Link Service on the control plane subnet
az network vnet subnet update `
  --name "$env:AZR_CLUSTER-aro-control-subnet-$env:AZR_RESOURCE_LOCATION" `
  --resource-group $env:AZR_RESOURCE_GROUP `
  --vnet-name "$env:AZR_CLUSTER-aro-vnet-$env:AZR_RESOURCE_LOCATION" `
  --disable-private-link-service-network-policies true
Write-Output "Private link service network policies disabled for $env:AZR_CLUSTER-aro-control-subnet-$env:AZR_RESOURCE_LOCATION"

# Create cluster
az aro create `
  --resource-group $env:AZR_RESOURCE_GROUP `
  --name $env:AZR_CLUSTER `
  --vnet "$env:AZR_CLUSTER-aro-vnet-$env:AZR_RESOURCE_LOCATION" `
  --master-subnet "$env:AZR_CLUSTER-aro-control-subnet-$env:AZR_RESOURCE_LOCATION" `
  --worker-subnet "$env:AZR_CLUSTER-aro-machine-subnet-$env:AZR_RESOURCE_LOCATION" `
  --pull-secret @$env:AZR_PULL_SECRET
Write-Output "Cluster $env:AZR_CLUSTER creation initiated. This may take around 30-40 minutes to complete."

# get cluster credentials
az aro list-credentials `
  --name $env:AZR_CLUSTER `
  --resource-group $env:AZR_RESOURCE_GROUP `
  -o tsv
Write-Output "Cluster credentials retrieved. You can now use the OpenShift CLI (oc) to interact with your cluster."
az aro show `
  --name $env:AZR_CLUSTER `
  --resource-group $env:AZR_RESOURCE_GROUP `
  -o tsv --query consoleProfile
Write-Output "Access the OpenShift console using the URL above and log in with the credentials retrieved."