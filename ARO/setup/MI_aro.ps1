# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND

# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"

# Set Location
$env:LOCATION = "uksouth"
# or eastus
#$env:LOCATION = "eastus"
Write-Output "Location set to: $env:LOCATION"

# Create a resource group name using the random number
$env:RG_NAME = "aroresourcegroup$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# set cluster name
$env:CLUSTER_NAME = "AROCluster$RAND"
$env:CLUSTER_VERSION = "4.19.20"
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

# Validate quota requirements
Write-Output "Validating quota requirements..."

$quotaInfo = az vm list-usage -l $env:LOCATION --query "[?contains(name.value, 'standardDSv5Family')]" -o json | ConvertFrom-Json

if ($quotaInfo -and $quotaInfo.Count -gt 0 -and $quotaInfo[0].currentValue -gt 0) {
    $availableCores = $quotaInfo[0].limit - $quotaInfo[0].currentValue
    
    if ($availableCores -lt 44) {
        Write-Output "Insufficient quota: Need 44 cores, available: $availableCores"
        Write-Output "Request quota increase for Standard DSv5 Family vCPUs at:"
        Write-Output "https://portal.azure.com/#view/Microsoft_Azure_Support/NewSupportRequestV3Blade/issueType/quota"
        exit 1
    }
    
    Write-Output "Quota validation passed: $availableCores cores available"
} else {
    Write-Output "Cannot validate quota for Standard DSv5 Family in $env:LOCATION"
    Write-Output "Proceeding with cluster creation..."
}

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

# Remove existing ARO extension if present
$existingExt = az extension list --query "[?name=='aro'].name" -o tsv
if ($existingExt) {
    Write-Output "Removing existing ARO extension..."
    az extension remove --name aro
}

# Install ARO preview extension (skip if already installed)
Write-Output "Checking ARO extension..."
$aroExtInstalled = az extension show --name aro 2>$null
if (-not $aroExtInstalled) {
    Write-Output "Installing ARO preview extension..."
    $extensionUrl = "https://aka.ms/az-aroext-latest"
    $fileName = "aro-1.0.12-py2.py3-none-any.whl"
    
    Invoke-WebRequest -Uri $extensionUrl -OutFile $fileName -MaximumRedirection 10
    az extension add --source $fileName --yes
    Remove-Item $fileName -ErrorAction SilentlyContinue
} else {
    Write-Output "ARO extension already installed"
}

# Create managed identities
Write-Output "Creating managed identities..."

$identities = @(
    "aro-cluster",
    "cloud-controller-manager",
    "ingress",
    "machine-api",
    "disk-csi-driver",
    "cloud-network-config",
    "image-registry",
    "file-csi-driver",
    "aro-operator"
)

foreach ($identity in $identities) {
    Write-Output "  Creating identity: $identity"
    az identity create --resource-group $env:RG_NAME --name $identity --location $env:LOCATION
}

# Get subscription ID
$subscriptionId = az account show --query 'id' -o tsv

# Assign roles
Write-Output "Assigning role assignments..."
Write-Output "Waiting 30 seconds for identity propagation..."
Start-Sleep -Seconds 30

# Cluster identity permissions over other identities
$clusterPrincipalId = az identity show --resource-group $env:RG_NAME --name aro-cluster --query principalId -o tsv

$operatorIdentities = @(
    "aro-operator",
    "cloud-controller-manager",
    "ingress",
    "machine-api",
    "disk-csi-driver",
    "cloud-network-config",
    "image-registry",
    "file-csi-driver"
)

foreach ($identity in $operatorIdentities) {
    Write-Output "  Assigning cluster identity permissions to $identity"
    az role assignment create `
        --assignee-object-id $clusterPrincipalId `
        --assignee-principal-type ServicePrincipal `
        --role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/ef318e2a-8334-4a05-9e4a-295a196c6a6e" `
        --scope "/subscriptions/$subscriptionId/resourcegroups/$env:RG_NAME/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$identity"
}

Write-Output "  Assigning network permissions to operators..."

# Cloud Controller Manager - master and worker subnets
$ccmPrincipalId = az identity show --resource-group $env:RG_NAME --name cloud-controller-manager --query principalId -o tsv
az role assignment create `
--assignee-object-id $ccmPrincipalId `
--assignee-principal-type ServicePrincipal `
--role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/a1f96423-95ce-4224-ab27-4e3dc72facd4" `
--scope "/subscriptions/$subscriptionId/resourceGroups/$env:RG_NAME/providers/Microsoft.Network/virtualNetworks/$env:VNET_NAME/subnets/master-subnet"
az role assignment create `
--assignee-object-id $ccmPrincipalId `
--assignee-principal-type ServicePrincipal `
--role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/a1f96423-95ce-4224-ab27-4e3dc72facd4" `
--scope "/subscriptions/$subscriptionId/resourceGroups/$env:RG_NAME/providers/Microsoft.Network/virtualNetworks/$env:VNET_NAME/subnets/worker-subnet"

# Ingress - master and worker subnets
$ingressPrincipalId = az identity show --resource-group $env:RG_NAME --name ingress --query principalId -o tsv
az role assignment create `
--assignee-object-id $ingressPrincipalId `
--assignee-principal-type ServicePrincipal `
--role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/0336e1d3-7a87-462b-b6db-342b63f7802c" `
--scope "/subscriptions/$subscriptionId/resourceGroups/$env:RG_NAME/providers/Microsoft.Network/virtualNetworks/$env:VNET_NAME/subnets/master-subnet"
az role assignment create `
--assignee-object-id $ingressPrincipalId `
--assignee-principal-type ServicePrincipal `
--role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/0336e1d3-7a87-462b-b6db-342b63f7802c" `
--scope "/subscriptions/$subscriptionId/resourceGroups/$env:RG_NAME/providers/Microsoft.Network/virtualNetworks/$env:VNET_NAME/subnets/worker-subnet"

# Machine API - master and worker subnets
$machineApiPrincipalId = az identity show --resource-group $env:RG_NAME --name machine-api --query principalId -o tsv
az role assignment create `
--assignee-object-id $machineApiPrincipalId `
--assignee-principal-type ServicePrincipal `
--role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/0358943c-7e01-48ba-8889-02cc51d78637" `
--scope "/subscriptions/$subscriptionId/resourceGroups/$env:RG_NAME/providers/Microsoft.Network/virtualNetworks/$env:VNET_NAME/subnets/master-subnet"
az role assignment create `
--assignee-object-id $machineApiPrincipalId `
--assignee-principal-type ServicePrincipal `
--role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/0358943c-7e01-48ba-8889-02cc51d78637" `
--scope "/subscriptions/$subscriptionId/resourceGroups/$env:RG_NAME/providers/Microsoft.Network/virtualNetworks/$env:VNET_NAME/subnets/worker-subnet"

# Cloud Network Config - vnet level
$cloudNetPrincipalId = az identity show --resource-group $env:RG_NAME --name cloud-network-config --query principalId -o tsv
az role assignment create `
--assignee-object-id $cloudNetPrincipalId `
--assignee-principal-type ServicePrincipal `
--role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/be7a6435-15ae-4171-8f30-4a343eff9e8f" `
--scope "/subscriptions/$subscriptionId/resourceGroups/$env:RG_NAME/providers/Microsoft.Network/virtualNetworks/$env:VNET_NAME"

# File CSI Driver - vnet level
$fileCsiPrincipalId = az identity show --resource-group $env:RG_NAME --name file-csi-driver --query principalId -o tsv
az role assignment create `
--assignee-object-id $fileCsiPrincipalId `
--assignee-principal-type ServicePrincipal `
--role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/0d7aedc0-15fd-4a67-a412-efad370c947e" `
--scope "/subscriptions/$subscriptionId/resourceGroups/$env:RG_NAME/providers/Microsoft.Network/virtualNetworks/$env:VNET_NAME"

# Image Registry - vnet level
$imageRegPrincipalId = az identity show --resource-group $env:RG_NAME --name image-registry --query principalId -o tsv
az role assignment create `
--assignee-object-id $imageRegPrincipalId `
--assignee-principal-type ServicePrincipal `
--role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/8b32b316-c2f5-4ddf-b05b-83dacd2d08b5" `
--scope "/subscriptions/$subscriptionId/resourceGroups/$env:RG_NAME/providers/Microsoft.Network/virtualNetworks/$env:VNET_NAME"

# ARO Operator - master and worker subnets
$aroOpPrincipalId = az identity show --resource-group $env:RG_NAME --name aro-operator --query principalId -o tsv
az role assignment create `
--assignee-object-id $aroOpPrincipalId `
--assignee-principal-type ServicePrincipal `
--role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/4436bae4-7702-4c84-919b-c4069ff25ee2" `
--scope "/subscriptions/$subscriptionId/resourceGroups/$env:RG_NAME/providers/Microsoft.Network/virtualNetworks/$env:VNET_NAME/subnets/master-subnet"
az role assignment create `
--assignee-object-id $aroOpPrincipalId `
--assignee-principal-type ServicePrincipal `
--role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/4436bae4-7702-4c84-919b-c4069ff25ee2" `
--scope "/subscriptions/$subscriptionId/resourceGroups/$env:RG_NAME/providers/Microsoft.Network/virtualNetworks/$env:VNET_NAME/subnets/worker-subnet"

# First-party service principal role assignment
$aroRpSpObjectId = az ad sp list --display-name "Azure Red Hat OpenShift RP" --query '[0].id' -o tsv
az role assignment create `
--assignee-object-id $aroRpSpObjectId `
--assignee-principal-type ServicePrincipal `
--role "/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7" `
--scope "/subscriptions/$subscriptionId/resourceGroups/$env:RG_NAME/providers/Microsoft.Network/virtualNetworks/$env:VNET_NAME"

Write-Output "Role assignments completed"

Write-Output "Waiting 30 seconds for role propagation..."
Start-Sleep -Seconds 30

# Create ARO cluster with managed identities
Write-Output "Creating ARO cluster with managed identities..."
# create ARO cluster
az aro create `
  --resource-group $env:RG_NAME `
  --name $env:CLUSTER_NAME `
  --vnet $env:VNET_NAME `
  --master-subnet "master-subnet" `
  --worker-subnet "worker-subnet" `
  --location $env:LOCATION `
  --version $env:CLUSTER_VERSION `
  --enable-managed-identity `
  --assign-cluster-identity aro-cluster `
  --assign-platform-workload-identity file-csi-driver file-csi-driver `
  --assign-platform-workload-identity cloud-controller-manager cloud-controller-manager `
  --assign-platform-workload-identity ingress ingress `
  --assign-platform-workload-identity image-registry image-registry `
  --assign-platform-workload-identity machine-api machine-api `
  --assign-platform-workload-identity cloud-network-config cloud-network-config `
  --assign-platform-workload-identity aro-operator aro-operator `
  --assign-platform-workload-identity disk-csi-driver disk-csi-driver `
  --pull-secret '@pull-secret.txt'


Write-Output ""
Write-Output "ARO cluster creation initiated!"
Write-Output "This will take 30-45 minutes to complete."