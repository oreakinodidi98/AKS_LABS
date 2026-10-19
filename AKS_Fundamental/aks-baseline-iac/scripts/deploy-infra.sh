#!/bin/bash
set -e

# Deploy Infrastructure Script
# This script deploys the AKS baseline infrastructure using Terraform

echo "==================================="
echo "AKS Baseline Infrastructure Deploy"
echo "==================================="

# Check prerequisites
command -v az >/dev/null 2>&1 || { echo "Azure CLI is required but not installed. Aborting." >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed. Aborting." >&2; exit 1; }

# Check if logged in to Azure
echo "Checking Azure login..."
az account show >/dev/null 2>&1 || { echo "Please login to Azure first: az login" >&2; exit 1; }

# Navigate to terraform directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/../terraform"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "terraform.tfvars not found!"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and update with your values:"
    echo "  cp terraform.tfvars.example terraform.tfvars"
    exit 1
fi

# Initialize Terraform
echo ""
echo "Initializing Terraform..."
terraform init

# Validate configuration
echo ""
echo "Validating Terraform configuration..."
terraform validate

# Plan deployment
echo ""
echo "Planning infrastructure deployment..."
terraform plan -out=tfplan

# Prompt for confirmation
read -p "Do you want to apply this plan? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Apply deployment
echo ""
echo "Deploying infrastructure..."
terraform apply tfplan

# Get outputs
echo ""
echo "==================================="
echo "Deployment Complete!"
echo "==================================="
terraform output

# Configure kubectl
echo ""
echo "Configuring kubectl..."
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_CLUSTER=$(terraform output -raw aks_cluster_name)
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --overwrite-existing

echo ""
echo "kubectl configured successfully!"
echo "You can now deploy applications using: ./scripts/deploy-apps.sh"
