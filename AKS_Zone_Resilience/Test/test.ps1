# General variables
$RAND = Get-Random
# Set it as an environment variable
$env:RAND = $RAND
# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"
# Set Location
$env:LOCATION = "swedencentral"
Write-Output "Location set to: $env:LOCATION"
# Resource group variables
$env:RG_NAME = "zonal$RAND"
Write-Output "Resource group name: $env:RG_NAME"

# Azure account variables
$env:AZURE_SUBSCRIPTION_ID = az account show --query id -o tsv
Write-Output "Subscription ID: $env:AZURE_SUBSCRIPTION_ID"
$env:AZURE_TENANT_ID = az account show --query tenantId -o tsv
Write-Output "Tenant ID: $env:AZURE_TENANT_ID"
$subscriptionScope = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID"

# Networking variables
$env:vnet = "zonal-vnet"
$env:vnetPrefix = "10.50.0.0/16"
$env:systemSubnet = "system-subnet"
$env:systemSubnetPrefix = "10.50.1.0/24"
$env:userSubnet = "user-subnet"
$env:userSubnetPrefix = "10.50.2.0/24"
$env:podSubnet = "pod-subnet"
$env:podSubnetPrefix = "10.50.3.0/24"
$env:bastionSubnet = "AzureBastionSubnet"
$env:bastionSubnetPrefix = "10.50.4.0/24"
$env:myIp = (Invoke-RestMethod -Uri "https://api.ipify.org")
Write-Output "Current public IP: $env:myIp"

# AKS variables
$env:AKS_NAME = "myakscluster$RAND"
Write-Output "AKS cluster name: $env:AKS_NAME"
# Get the latest Kubernetes version available in the region
$env:K8S_VERSION = $(az aks get-versions -l $env:LOCATION --query "values[?isDefault==``true``].version | [0]" -o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"
$env:systemNodePoolName = "systempool$RAND"
write-output "System node pool name: $env:systemNodePoolName"
$env:userNodePoolName = "userpool$RAND"
write-output "User node pool name: $env:userNodePoolName"
$env:vmSize = "Standard_DS2_v2"
write-output "Node pool VM size: $env:vmSize can also use Standard_D4ds_v4, Standard_F8s_v2, Standard_D4ads_v5"
$env:nodeCount = 2
write-output "Node count: $env:nodeCount"
$env:minCount = 2
write-output "Min count: $env:minCount"
$env:maxCount = 6
write-output "Max count: $env:maxCount"
$env:maxPods = 100
write-output "Max pods: $env:maxPods"
$env:test_namespace = "disk-test"
write-output "Test namespace: $env:test_namespace"


# Log Analytics variables
$env:WORKSPACE_NAME = "zonalworkspace$RAND"
Write-Output "Workspace name: $env:WORKSPACE_NAME"

# Iterate node pools
foreach ($i in 1..3) {
    $userNodePoolName = '{0}{1:D2}' -f $env:userNodePoolName, $i

    Write-Host "Retrieving the node count for the [$userNodePoolName] node pool..."
    $count = az aks nodepool show `
        --name $userNodePoolName `
        --cluster-name $env:AKS_NAME `
        --resource-group $env:RG_NAME `
        --query count `
        --output tsv `
        --only-show-errors

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not retrieve node pool [$userNodePoolName]. Skipping it."
        continue
    }

    Write-Host "Disabling autoscaling for the [$userNodePoolName] node pool..."
    az aks nodepool update `
        --cluster-name $env:AKS_NAME `
        --name $userNodePoolName `
        --resource-group $env:RG_NAME `
        --disable-cluster-autoscaler `
        --only-show-errors > $null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to disable autoscaling for [$userNodePoolName]."
    }

    if ([int]$count -ne $env:nodeCount) {
        Write-Host "Scaling the [$userNodePoolName] node pool to $env:nodeCount nodes..."
        az aks nodepool scale `
            --cluster-name $env:AKS_NAME `
            --name $userNodePoolName `
            --resource-group $env:RG_NAME `
            --node-count $env:nodeCount `
            --only-show-errors > $null

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to scale [$userNodePoolName]."
        }
    }
    else {
        Write-Host "The [$userNodePoolName] node pool is already scaled to $env:nodeCount nodes."
    }
}

# create namespace in cluster
kubectl create namespace $env:test_namespace

# create persistent volume claim in the namespace
kubectl apply -f zne-pvc.yml -n $env:test_namespace
write-output "Persistent volume claim created in namespace $env:test_namespace"
write-output "Persistent volume claim details: PVC uses the managed-csi-premium built-in storage class that leverages Premium_LRS storage. LRS persistent volumes can only be attached by pods in the same availability zone. Therefore, it is necessary to create three persistent volume claims, one for each availability zone"

# Get info about the nodes in cluster
kubectl get nodes -L kubernetes.azure.com/agentpool,topology.kubernetes.io/region,topology.kubernetes.io/zone

# Get info about the pods in the test namespace
kubectl get pods -n $env:test_namespace -o wide
kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP,HOSTIP:.status.hostIP,NODE:.spec.nodeName -n $env:test_namespace
write-output "Pods in namespace $env:test_namespace are running on nodes in different availability zones. This demonstrates that the persistent volume claims are being used by pods in different availability zones, which is a key feature of zone-redundant AKS clusters."

# cordon and drain the nodes of the user01 node pool which nodes are located in westeurope-1 zone.
kubectl cordon $(kubectl get nodes -l kubernetes.azure.com/agentpool=user01,topology.kubernetes.io/zone=westeurope-1 -o name)
kubectl drain $(kubectl get nodes -l kubernetes.azure.com/agentpool=user01,topology.kubernetes.io/zone=westeurope-1 -o name) --ignore-daemonsets --delete-emptydir-data --force
write-output "Nodes in the user01 node pool located in westeurope-1 zone have been cordoned and drained. This simulates a failure in that availability zone."

#  Retrieve information about the nodes in your Kubernetes cluster
kubectl get nodes -L kubernetes.azure.com/agentpool,topology.kubernetes.io/region,topology.kubernetes.io/zone
kubectl get pods -n $env:test_namespace -o wide
kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP,HOSTIP:.status.hostIP,NODE:.spec.nodeName -n $env:test_namespace
write-output "After cordoning and draining the nodes in the user01 node pool located in westeurope-1 zone, the remaining nodes in the cluster are still available to run workloads. This demonstrates that the zone-redundant AKS cluster is resilient to failures in a single availability zone."

# uncordon the nodes of the user01 node pool which nodes are located in westeurope-1 zone.
kubectl uncordon $(kubectl get nodes -l kubernetes.azure.com/agentpool=user01,topology.kubernetes.io/zone=westeurope-1 -o name)
write-output "Nodes in the user01 node pool located in westeurope-1 zone have been uncordoned. This allows workloads to be scheduled on those nodes again."


