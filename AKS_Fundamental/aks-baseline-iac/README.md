# AKS Baseline Architecture Prototype

This prototype implements an Azure Kubernetes Service (AKS) baseline architecture without monitoring components.

## Architecture Overview

This implementation includes:
- **Networking**: Virtual Network with dedicated subnets for AKS and Application Gateway
- **Compute**: AKS cluster with system and user node pools
- **Ingress**: Application Gateway for external traffic routing
- **Security**: Azure Key Vault for secrets, Managed Identity for authentication
- **Storage**: Azure Storage Account for persistent volumes
- **Data**: Azure SQL Database for application data
- **Registry**: Azure Container Registry for container images

**Excluded**: All monitoring components (Application Insights, Log Analytics, Azure Monitor, Prometheus, Grafana)

## Project Structure

```
aks-baseline-prototype/
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # Main configuration
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values
│   ├── providers.tf       # Provider configuration
│   ├── modules/           # Reusable modules
│   │   ├── network/       # VNet and subnets
│   │   ├── aks/           # AKS cluster
│   │   ├── acr/           # Container Registry
│   │   ├── keyvault/      # Key Vault
│   │   ├── database/      # Azure SQL
│   │   ├── storage/       # Storage Account
│   │   └── appgateway/    # Application Gateway
│   └── terraform.tfvars.example
├── kubernetes/            # K8s manifests
│   ├── namespaces/        # Namespace definitions
│   ├── deployments/       # Application deployments
│   ├── services/          # Service definitions
│   └── ingress/           # Ingress configurations
├── src/                   # Sample applications
│   ├── WebApi/            # .NET Web API sample
│   └── WebApp/            # .NET Web App sample
├── scripts/               # Deployment scripts
│   ├── deploy-infra.sh    # Deploy infrastructure
│   ├── deploy-apps.sh     # Deploy applications
│   └── cleanup.sh         # Cleanup resources
└── README.md
```

## Prerequisites

- Azure CLI (v2.50+)
- Terraform (v1.5+)
- kubectl (v1.28+)
- Docker
- .NET 8.0 SDK

## Quick Start

### 1. Deploy Infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

### 2. Configure kubectl

```bash
az aks get-credentials --resource-group <rg-name> --name <aks-name>
```

### 3. Build and Push Container Images

```bash
cd ../src/WebApi
az acr login --name <acr-name>
docker build -t <acr-name>.azurecr.io/webapi:v1 .
docker push <acr-name>.azurecr.io/webapi:v1
```

### 4. Deploy Applications

```bash
cd ../../kubernetes
kubectl apply -f namespaces/
kubectl apply -f deployments/
kubectl apply -f services/
kubectl apply -f ingress/
```

## Configuration

### Key Variables

Edit `terraform/terraform.tfvars`:

- `project_name`: Project identifier (e.g., "aks-baseline")
- `environment`: Environment name (e.g., "dev", "prod")
- `location`: Azure region (e.g., "eastus")
- `kubernetes_version`: AKS version (e.g., "1.28")

## Security Considerations

- Managed Identity is used for AKS to access ACR and Key Vault
- Network policies restrict pod-to-pod communication
- Private endpoints can be enabled for PaaS services
- RBAC is configured for cluster access control

## Next Steps

- Enable Azure Policy for AKS
- Configure network policies
- Add pod security standards
- Implement GitOps with Flux/ArgoCD
- Set up disaster recovery

## License

MIT License - This is a demonstration project for workshop/training purposes.
