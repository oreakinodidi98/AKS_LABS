# Cleanup Script (PowerShell)
# This script destroys all resources created by Terraform

Write-Host "==============================" -ForegroundColor Red
Write-Host "AKS Baseline Cleanup" -ForegroundColor Red
Write-Host "==============================" -ForegroundColor Red

# Navigate to terraform directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptPath "..\terraform")

# Warn user
Write-Host "`nWARNING: This will destroy all infrastructure resources!" -ForegroundColor Red
Write-Host "This action cannot be undone." -ForegroundColor Red
Write-Host ""
terraform show

Write-Host ""
$confirm = Read-Host "Are you absolutely sure you want to destroy all resources? (type 'yes' to confirm)"

if ($confirm -ne "yes") {
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    exit 0
}

# Delete Kubernetes resources first (optional but recommended)
Write-Host ""
$deleteK8s = Read-Host "Do you want to delete Kubernetes resources first? (yes/no)"
if ($deleteK8s -eq "yes") {
    Write-Host "Deleting Kubernetes resources..." -ForegroundColor Yellow
    Set-Location "..\kubernetes"
    kubectl delete -f ingress\ --ignore-not-found=true
    kubectl delete -f services\ --ignore-not-found=true
    kubectl delete -f deployments\ --ignore-not-found=true
    kubectl delete -f namespaces\ --ignore-not-found=true
    Set-Location "..\terraform"
}

# Destroy infrastructure
Write-Host "`nDestroying infrastructure..." -ForegroundColor Yellow
terraform destroy

Write-Host "`n==============================" -ForegroundColor Green
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
