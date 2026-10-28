##############################################################################
# AKS App Routing Add-On Migration Demo - Cleanup Script
# 
# Tears down all demo resources. Run after the demo is complete.
##############################################################################

$RG_NAME    = "rg-approuting-demo"
$AKS_NAME   = "aks-approuting-demo"

Write-Host "============================================" -ForegroundColor Red
Write-Host " Cleaning up App Routing Demo resources"     -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Red
Write-Host ""

# Remove app-routing ingress
Write-Host "[1/6] Removing App Routing Ingress resources..." -ForegroundColor Yellow
kubectl delete ingress myapp-ingress-addon -n myapp --ignore-not-found
kubectl delete ingress myapp-ingress-byo -n myapp --ignore-not-found

# Remove sample app
Write-Host "[2/6] Removing sample application..." -ForegroundColor Yellow
kubectl delete -f app-deployment.yaml --ignore-not-found

# Uninstall BYO Nginx (if still present)
Write-Host "[3/6] Removing BYO Nginx controller (if present)..." -ForegroundColor Yellow
helm uninstall ingress-nginx -n ingress-nginx 2>$null
kubectl delete namespace ingress-nginx --ignore-not-found

# Disable App Routing add-on
Write-Host "[4/6] Disabling App Routing add-on..." -ForegroundColor Yellow
az aks approuting disable --resource-group $RG_NAME --name $AKS_NAME 2>$null

# Verify cleanup
Write-Host "[5/6] Verifying cleanup..." -ForegroundColor Yellow
Write-Host "  Namespaces:"
kubectl get ns | Select-String "myapp|ingress-nginx|app-routing"
Write-Host "  IngressClasses:"
kubectl get ingressclass 2>$null

# (Optional) Delete the entire cluster
Write-Host ""
Write-Host "[6/6] (Optional) Delete the AKS cluster and resource group?" -ForegroundColor Yellow
Write-Host "  Run the following command to delete everything:" -ForegroundColor DarkGray
Write-Host "  az group delete --name $RG_NAME --yes --no-wait" -ForegroundColor DarkGray

Write-Host ""
Write-Host "Cleanup complete." -ForegroundColor Green
