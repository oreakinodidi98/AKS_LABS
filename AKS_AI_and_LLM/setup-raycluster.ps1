# Set Ray variables:
$env:RAY_NAMESPACE="ray-system"
$env:RAY_CLUSTER_NAME="raycluster-ml"
$env:RAY_SERVICE_NAME="ray-service"
$env:RAY_JOB_NAME="ray-job"

# Retrieve the Terraform outputs and store in variables
$env:system_node_pool_name=$(terraform output -raw system_node_pool_name)
$env:aks_cluster_name=$(terraform output -raw aks_cluster_name)
write-host "Terraform outputs retrieved and stored in environment variables."

# Get AKS credentials for the cluster
az aks get-credentials --resource-group $env:RG_NAME --name $env:aks_cluster_name
write-host "AKS credentials have been retrieved and configured for kubectl."

# Create the kuberay namespace
$env:kuberay_namespace="kuberay"
kubectl create namespace $env:kuberay_namespace

# Output the current Kubernetes context
$env:current_context = $(kubectl config current-context)
write-host "Current Kubernetes context: $env:current_context"

# Output the nodes in the cluster
kubectl get nodes -o wide
kubectl top nodes

# Check Helm version
helm version

# Add the KubeRay Helm repository
helm repo add kuberay https://ray-project.github.io/kuberay-helm/

# Update the Helm repository
helm repo update

# Install or upgrade the KubeRay operator using Helm
helm upgrade `
--install `
--cleanup-on-fail `
--wait `
--timeout 10m0s `
--namespace "$env:RAY_NAMESPACE" `
--create-namespace kuberay-operator kuberay/kuberay-operator `
--version 1.1.1

# Output the pods in the kuberay namespace
kubectl get pods -n $env:RAY_NAMESPACE
#kubectl get crd | grep ray

# deploy Ray cluster using the ray-cluster.yaml file
kubectl apply -f ./raycluster/ray-cluster.yaml

# Wait for the cluster to be ready
kubectl get raycluster -n $env:RAY_NAMESPACE -w

# Check the status of Ray pods
kubectl get pods -n $env:RAY_NAMESPACE
kubectl get svc -n $env:RAY_NAMESPACE

# Port forward to access the Ray dashboard
kubectl port-forward -n $env:RAY_NAMESPACE service/$env:RAY_CLUSTER_NAME-head-svc 8265:8265