# Deployment Scripts

This directory contains scripts to deploy and manage the AKS baseline infrastructure and applications.

## Available Scripts

### deploy-infra.sh
Deploys the Azure infrastructure using Terraform.

**Prerequisites:**
- Azure CLI installed and logged in
- Terraform installed (v1.5+)
- terraform.tfvars configured

**Usage:**
```bash
./deploy-infra.sh
```

**What it does:**
1. Validates Azure login
2. Initializes Terraform
3. Validates configuration
4. Creates execution plan
5. Applies infrastructure changes
6. Configures kubectl

### deploy-apps.sh
Builds and deploys applications to AKS.

**Prerequisites:**
- Infrastructure deployed (run deploy-infra.sh first)
- Docker installed
- kubectl configured

**Usage:**
```bash
./deploy-apps.sh
```

**What it does:**
1. Logs in to Azure Container Registry
2. Builds Docker images for WebApi and WebApp
3. Pushes images to ACR
4. Deploys Kubernetes manifests
5. Configures services and ingress

### cleanup.sh
Destroys all infrastructure resources.

**WARNING:** This is destructive and cannot be undone!

**Usage:**
```bash
./cleanup.sh
```

**What it does:**
1. Optionally deletes Kubernetes resources
2. Destroys Terraform-managed infrastructure
3. Removes all Azure resources

## Deployment Order

1. **First time setup:**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   cd ..
   ```

2. **Deploy infrastructure:**
   ```bash
   ./scripts/deploy-infra.sh
   ```

3. **Deploy applications:**
   ```bash
   ./scripts/deploy-apps.sh
   ```

4. **When finished, cleanup:**
   ```bash
   ./scripts/cleanup.sh
   ```

## Troubleshooting

### Script permission denied
Make scripts executable:
```bash
chmod +x scripts/*.sh
```

### Azure login issues
Ensure you're logged in:
```bash
az login
az account show
```

### kubectl not configured
If kubectl isn't configured after infrastructure deployment:
```bash
az aks get-credentials --resource-group <rg-name> --name <aks-name>
```

### ACR login fails
Ensure you have AcrPull permissions:
```bash
az acr login --name <acr-name>
```
