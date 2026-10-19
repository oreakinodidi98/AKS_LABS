#!/bin/bash
set -e

# Cleanup Script
# This script destroys all resources created by Terraform

echo "=============================="
echo "AKS Baseline Cleanup"
echo "=============================="

# Navigate to terraform directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/../terraform"

# Warn user
echo ""
echo "WARNING: This will destroy all infrastructure resources!"
echo "This action cannot be undone."
echo ""
terraform show

echo ""
read -p "Are you absolutely sure you want to destroy all resources? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Delete Kubernetes resources first (optional but recommended)
echo ""
read -p "Do you want to delete Kubernetes resources first? (yes/no): " delete_k8s
if [ "$delete_k8s" == "yes" ]; then
    echo "Deleting Kubernetes resources..."
    cd ../kubernetes
    kubectl delete -f ingress/ --ignore-not-found=true
    kubectl delete -f services/ --ignore-not-found=true
    kubectl delete -f deployments/ --ignore-not-found=true
    kubectl delete -f namespaces/ --ignore-not-found=true
    cd ../terraform
fi

# Destroy infrastructure
echo ""
echo "Destroying infrastructure..."
terraform destroy

echo ""
echo "=============================="
echo "Cleanup Complete!"
echo "=============================="
