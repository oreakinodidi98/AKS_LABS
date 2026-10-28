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
--namespace "$env:kuberay_namespace" `
--create-namespace kuberay-operator kuberay/kuberay-operator `
--version 1.1.1

# Output the pods in the kuberay namespace
kubectl get pods -n $env:kuberay_namespace
#kubectl get crd | grep ray

# Download the PyTorch MNIST job YAML file
curl -LO https://raw.githubusercontent.com/ray-project/kuberay/master/ray-operator/config/samples/pytorch-mnist/ray-job.pytorch-mnist.yaml

# Train a PyTorch Model on Fashion MNIST
kubectl apply -n $env:kuberay_namespace -f ray-job.pytorch-mnist.yaml

# Output the pods in the kuberay namespace
kubectl get pods -n $env:kuberay_namespace

# Get the status of the Ray job
$env:job_status=$(kubectl get rayjobs -n $env:kuberay_namespace -o jsonpath='{.items[0].status.jobDeploymentStatus}')
write-host "Ray job status: $env:job_status"

# Get the Ray cluster head service
$env:rayclusterhead = (kubectl get service -n $env:kuberay_namespace | Select-String 'rayjob-pytorch-mnist-raycluster' | Select-String 'ClusterIP' | ForEach-Object { ($_.Line -split '\s+')[0] })
write-host "Ray cluster head service: $env:rayclusterhead"

# create a service of type NodePort for the Ray cluster head
kubectl expose service $env:rayclusterhead --type=NodePort -n $env:kuberay_namespace --port=80 --target-port=8265 --name=ray-dash 

# ingress for the KubeRay dashboard

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ray-dash
  namespace: kuberay
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: webapprouting.kubernetes.azure.com
  rules:
  - http:
      paths:
      - backend:
          service:
            name: ray-dash
            port:
              number: 80
        path: /
        pathType: Prefix
EOF

# public IP address of the ingress controller
$env:lb_public_ip = kubectl get svc nginx -n app-routing-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
write-host "Public IP address of the ingress controller: $env:lb_public_ip"

write-host "KubeRay Dashboard URL: http://$env:lb_public_ip/"