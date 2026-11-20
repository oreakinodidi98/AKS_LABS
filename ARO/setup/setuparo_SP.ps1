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
$env:MANAGED_RESOURCE_GROUP = "aro-$RAND-managed-rg"
Write-Output "Managed resource group name: $env:MANAGED_RESOURCE_GROUP"
$env:SUBSCRIPTION_ID=$(az account show --query id -o tsv)
write-Output "Subscription ID set to: $env:SUBSCRIPTION_ID"
$env:WORKER_VM_SIZE = "Standard_D4s_v5"
Write-Output "Worker VM size set to: $env:WORKER_VM_SIZE"

# set cluster name
$env:CLUSTER_NAME = "AROCluster$RAND"
$env:CLUSTER_VERSION = "4.19.20"
Write-Output "Cluster name: $env:CLUSTER_NAME"
Write-Output "Cluster version: $env:CLUSTER_VERSION"

# Service principal for the ARO cluster
$env:END_DATE=$(date -d "+1 days" '+%Y-%m-%d')
$env:CREDENTIAL_DISPLAY_NAME = "aro-${env:CLUSTER_NAME}-$(date '+%Y%m%d%H%M%S')"
$env:CLIENT_ID=$(az ad sp create-for-rbac --name $env:CREDENTIAL_DISPLAY_NAME --query appId -o tsv)
Write-Output "Client ID set to: $env:CLIENT_ID"
$env:CLIENT_SECRET=$(az ad sp credential reset --name $env:CREDENTIAL_DISPLAY_NAME --end-date $env:END_DATE --query password -o tsv)
Write-Output "Client Secret set to: $env:CLIENT_SECRET"

# Create the resource group
az group create --name $env:RG_NAME --location $env:LOCATION

az group update `
  --name $env:RG_NAME `
  --set tags.SecurityControl=Ignore
Write-Output "Resource group $env:RG_NAME updated with SecurityControl=Ignore"

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

# The watcher cannot guarantee tagging before deployment or override deny assignments.
$tagWatcher = Start-Job -ArgumentList $env:MANAGED_RESOURCE_GROUP, $env:SUBSCRIPTION_ID -ScriptBlock {
  param($managedResourceGroup, $subscriptionId)

  Write-Output "Waiting for managed resource group: $managedResourceGroup"
  for ($attempt = 0; $attempt -lt 1800; $attempt++) {
    $exists = az group exists --name $managedResourceGroup --subscription $subscriptionId --output tsv
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to check managed resource group existence (exit code $LASTEXITCODE)."
    }

    if ($exists -eq 'true') {
      az group update --name $managedResourceGroup --subscription $subscriptionId `
        --set tags.SecurityControl=Ignore --output none
      if ($LASTEXITCODE -ne 0) {
        throw "Failed to tag managed resource group $managedResourceGroup (exit code $LASTEXITCODE)."
      }
      Write-Output "SecurityControl=Ignore applied to: $managedResourceGroup"
      return
    }

    Start-Sleep -Seconds 1
  }
  throw "Timed out waiting for managed resource group $managedResourceGroup."
}

try {
  az aro create `
    --resource-group $env:RG_NAME `
    --name $env:CLUSTER_NAME `
    --vnet $env:VNET_NAME `
    --master-subnet master-subnet `
    --worker-subnet worker-subnet `
    --worker-vm-size $env:WORKER_VM_SIZE `
    --pull-secret '@pull-secret.json' `
    --client-id $env:CLIENT_ID `
    --client-secret $env:CLIENT_SECRET `
    --cluster-resource-group $env:MANAGED_RESOURCE_GROUP

  if ($LASTEXITCODE -ne 0) {
    throw "az aro create failed with exit code $LASTEXITCODE."
  }
  Wait-Job -Job $tagWatcher | Out-Null
}
finally {
  if ($tagWatcher.State -eq 'Running') {
    Stop-Job -Job $tagWatcher
  }
  $watcherState = $tagWatcher.State
  Receive-Job -Job $tagWatcher -ErrorAction Continue
  Remove-Job -Job $tagWatcher
}

if ($watcherState -ne 'Completed') {
  throw "Managed resource group tag watcher ended in state $watcherState."
}

az aro show `
  --name $env:CLUSTER_NAME `
  --resource-group $env:RG_NAME `
  --query "{state:provisioningState,console:consoleProfile.url,api:apiserverProfile.url}" `
  --output json
if ($LASTEXITCODE -ne 0) {
  throw "az aro show failed with exit code $LASTEXITCODE."
}