# Deploy Infrastructure Script (PowerShell)
# This script deploys the AKS baseline infrastructure using Terraform

param(
    [switch]$AutoApprove
)

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "AKS Baseline Infrastructure Deploy" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "`nChecking prerequisites..."
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Azure CLI is required but not installed. Aborting." -ForegroundColor Red
    exit 1
}
if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "Terraform is required but not installed. Aborting." -ForegroundColor Red
    exit 1
}

# Check if logged in to Azure
Write-Host "Checking Azure login..."
try {
    az account show | Out-Null
} catch {
    Write-Host "Please login to Azure first: az login" -ForegroundColor Red
    exit 1
}

# Navigate to terraform directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptPath "..\terraform")

# Check if terraform.tfvars exists
if (!(Test-Path "terraform.tfvars")) {
    Write-Host "`nterraform.tfvars not found!" -ForegroundColor Red
    Write-Host "Please copy terraform.tfvars.example to terraform.tfvars and update with your values:"
    Write-Host "  copy terraform.tfvars.example terraform.tfvars"
    exit 1
}

# Initialize Terraform
Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
terraform init
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Validate configuration
Write-Host "`nValidating Terraform configuration..." -ForegroundColor Yellow
terraform validate
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Plan deployment
Write-Host "`nPlanning infrastructure deployment..." -ForegroundColor Yellow
terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Prompt for confirmation
if (!$AutoApprove) {
    $confirm = Read-Host "`nDo you want to apply this plan? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Apply deployment
Write-Host "`nDeploying infrastructure..." -ForegroundColor Yellow
terraform apply tfplan
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Get outputs
Write-Host "`n===================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
terraform output

# Configure kubectl
Write-Host "`nConfiguring kubectl..." -ForegroundColor Yellow
$resourceGroup = terraform output -raw resource_group_name
$aksCluster = terraform output -raw aks_cluster_name
az aks get-credentials --resource-group $resourceGroup --name $aksCluster --overwrite-existing

Write-Host "`nkubectl configured successfully!" -ForegroundColor Green
Write-Host "You can now deploy applications using: .\scripts\deploy-apps.ps1" -ForegroundColor Cyan
