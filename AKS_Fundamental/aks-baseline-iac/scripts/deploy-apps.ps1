# Deploy Applications Script (PowerShell)
# This script builds and deploys applications to AKS

Write-Host "================================" -ForegroundColor Cyan
Write-Host "AKS Baseline Application Deploy" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "`nChecking prerequisites..."
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Azure CLI is required but not installed. Aborting." -ForegroundColor Red
    exit 1
}
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "kubectl is required but not installed. Aborting." -ForegroundColor Red
    exit 1
}
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker is required but not installed. Aborting." -ForegroundColor Red
    exit 1
}

# Get script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptPath "..")

# Get ACR name from Terraform output
Set-Location "terraform"
$acrName = terraform output -raw acr_name
$acrLoginServer = terraform output -raw acr_login_server
$sqlServerFqdn = terraform output -raw sql_server_fqdn
$storageAccountName = terraform output -raw storage_account_name
Set-Location ".."

Write-Host "ACR Name: $acrName" -ForegroundColor Cyan
Write-Host "ACR Login Server: $acrLoginServer" -ForegroundColor Cyan

# Login to ACR
Write-Host "`nLogging in to Azure Container Registry..." -ForegroundColor Yellow
az acr login --name $acrName
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Build and push WebApi
Write-Host "`nBuilding WebApi..." -ForegroundColor Yellow
Set-Location "src\WebApi"
docker build -t "${acrLoginServer}/webapi:latest" .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Pushing WebApi to ACR..." -ForegroundColor Yellow
docker push "${acrLoginServer}/webapi:latest"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location "..\..\"

# Build and push WebApp
Write-Host "`nBuilding WebApp..." -ForegroundColor Yellow
Set-Location "src\WebApp"
docker build -t "${acrLoginServer}/webapp:latest" .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Pushing WebApp to ACR..." -ForegroundColor Yellow
docker push "${acrLoginServer}/webapp:latest"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location "..\..\"

# Deploy to Kubernetes
Write-Host "`nDeploying to Kubernetes..." -ForegroundColor Yellow

# Create namespaces
kubectl apply -f kubernetes\namespaces\

# Update deployment manifests with ACR name
Write-Host "Updating deployment manifests..." -ForegroundColor Yellow
$deploymentContent = Get-Content "kubernetes\deployments\applications.yaml" -Raw
$deploymentContent = $deploymentContent -replace '\${ACR_NAME}', $acrName
$deploymentContent | kubectl apply -f -

# Create services
kubectl apply -f kubernetes\services\

# Deploy ingress
kubectl apply -f kubernetes\ingress\

Write-Host "`n================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "`nNote: Secrets need to be configured manually." -ForegroundColor Yellow
Write-Host "Please update kubernetes\secrets\secrets.yaml.template with actual values"
Write-Host "and apply it using: kubectl apply -f kubernetes\secrets\secrets.yaml"
Write-Host "`nCheck deployment status:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -n applications"
Write-Host "  kubectl get svc -n applications"
Write-Host "  kubectl get ingress -n applications"
Write-Host "`nView logs:" -ForegroundColor Cyan
Write-Host "  kubectl logs -n applications -l app=webapi"
Write-Host "  kubectl logs -n applications -l app=webapp"
