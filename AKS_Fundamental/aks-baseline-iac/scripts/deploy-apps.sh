#!/bin/bash
set -e

# Deploy Applications Script
# This script builds and deploys applications to AKS

echo "================================"
echo "AKS Baseline Application Deploy"
echo "================================"

# Check prerequisites
command -v az >/dev/null 2>&1 || { echo "Azure CLI is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting." >&2; exit 1; }

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

# Get ACR name from Terraform output
cd terraform
ACR_NAME=$(terraform output -raw acr_name)
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
SQL_SERVER_FQDN=$(terraform output -raw sql_server_fqdn)
STORAGE_ACCOUNT_NAME=$(terraform output -raw storage_account_name)
cd ..

echo "ACR Name: $ACR_NAME"
echo "ACR Login Server: $ACR_LOGIN_SERVER"

# Login to ACR
echo ""
echo "Logging in to Azure Container Registry..."
az acr login --name "$ACR_NAME"

# Build and push WebApi
echo ""
echo "Building WebApi..."
cd src/WebApi
docker build -t "$ACR_LOGIN_SERVER/webapi:latest" .
echo "Pushing WebApi to ACR..."
docker push "$ACR_LOGIN_SERVER/webapi:latest"
cd ../..

# Build and push WebApp
echo ""
echo "Building WebApp..."
cd src/WebApp
docker build -t "$ACR_LOGIN_SERVER/webapp:latest" .
echo "Pushing WebApp to ACR..."
docker push "$ACR_LOGIN_SERVER/webapp:latest"
cd ../..

# Deploy to Kubernetes
echo ""
echo "Deploying to Kubernetes..."

# Create namespaces
kubectl apply -f kubernetes/namespaces/

# Update deployment manifests with ACR name
echo "Updating deployment manifests..."
sed "s/\${ACR_NAME}/$ACR_NAME/g" kubernetes/deployments/applications.yaml | kubectl apply -f -

# Create services
kubectl apply -f kubernetes/services/

# Update and create secrets (Note: In production, use Azure Key Vault CSI driver)
echo ""
echo "Note: Secrets need to be configured manually."
echo "Please update kubernetes/secrets/secrets.yaml.template with actual values"
echo "and apply it using: kubectl apply -f kubernetes/secrets/secrets.yaml"

# Deploy ingress
kubectl apply -f kubernetes/ingress/

echo ""
echo "================================"
echo "Deployment Complete!"
echo "================================"
echo ""
echo "Check deployment status:"
echo "  kubectl get pods -n applications"
echo "  kubectl get svc -n applications"
echo "  kubectl get ingress -n applications"
echo ""
echo "View logs:"
echo "  kubectl logs -n applications -l app=webapi"
echo "  kubectl logs -n applications -l app=webapp"
