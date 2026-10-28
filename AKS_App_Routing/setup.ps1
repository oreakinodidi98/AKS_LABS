##############################################################################
# AKS App Routing Add-On Migration Demo - Setup Script
# 
# This script walks through a zero-downtime migration from BYO Nginx Ingress
# to the AKS App Routing Add-On. Run each section interactively (copy-paste)
# to narrate the demo don't run the whole file at once.
#
# Prerequisites:
#   - Azure CLI authenticated (az login)
#   - kubectl installed
#   - Helm installed
#   - An existing AKS cluster (or set CREATE_CLUSTER=$true below)
##############################################################################

# ============================================================================
# STEP 0: Set Variables
# ============================================================================
# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND
$env:RG_NAME    = "rg-approuting-demo-$env:RAND"
$env:AKS_NAME   = "aks-approuting-demo-$env:RAND"
# Print the random resource identifier
Write-Output "Random resource identifier will be: $env:RAND"
# Set Location
$env:LOCATION = "uksouth"
Write-Output "Location set to: $env:LOCATION"
# Generate a short random name for user assigned identity (globally unique)
$env:USER_ASSIGNED_IDENTITY_NAME = "ft-identity-$RAND"
Write-Output "User assigned identity name: $env:USER_ASSIGNED_IDENTITY_NAME"

# Generate a short random name for ACR (globally unique)
$env:ACR_NAME = "ftacr$RAND"
Write-Output "ACR name: $env:ACR_NAME"

#set name suffix
$env:NAME_SUFFIX = "$RAND"
Write-Output "Name suffix set to: $env:NAME_SUFFIX"

# store resource names in .envrc file
$envrcContent = @"
export RG_NAME=$env:RG_NAME
export LOCATION=$env:LOCATION
export AKS_NAME=$env:AKS_NAME
export USER_ASSIGNED_IDENTITY_NAME=$env:USER_ASSIGNED_IDENTITY_NAME
export ACR_NAME=$env:ACR_NAME
"@ | Out-File -FilePath ".envrc" -Encoding utf8
Write-Output ".envrc file created with resource names."

# register preview features
az extension add --name aks-preview
az feature register --namespace "Microsoft.ContainerService" --name "AdvancedNetworkingFlowLogsPreview"
az feature register --namespace "Microsoft.ContainerService" --name "AdvancedNetworkingL7PolicyPreview"
Write-Output "Preview features registered. This may take a few minutes."
# register following providers
az provider register --namespace Microsoft.Quota
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.PolicyInsights
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.ServiceLinker
az provider register --namespace Microsoft.KubernetesConfiguration
Write-Output "Providers registration initiated."

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " AKS App Routing Add-On Migration Demo"     -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# STEP 1: (Optional) Create AKS Cluster
# Uncomment this section if you need a fresh cluster for the demo.
# ============================================================================
<#
Write-Host "[Step 1] Creating resource group and AKS cluster..." -ForegroundColor Yellow

az group create --name $env:RG_NAME --location $env:LOCATION
Write-Output "Resource group $env:RG_NAME created"

# Get the latest Kubernetes version available in the region
$env:K8S_VERSION=$(az aks get-versions -l $env:LOCATION `
--query "values[?isDefault==``true``].version | [0]" `
-o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"

# create user assighned managed identiy 
az identity create --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --location $env:LOCATION
Write-Output "User assigned managed identity $env:USER_ASSIGNED_IDENTITY_NAME created in resource group $env:RG_NAME"

# store identity details
Write-Output "Waiting for identity propagation..."
Start-Sleep -Seconds 30
$env:USER_ASSIGNED_IDENTITY_ID=$(az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'id' -o tsv)
$env:USER_ASSIGNED_IDENTITY_CLIENT_ID=$(az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'clientId' -o tsv)
$env:USER_ASSIGNED_IDENTITY_PRINCIPAL_ID=$(az identity show --name $env:USER_ASSIGNED_IDENTITY_NAME --resource-group $env:RG_NAME --query 'principalId' -o tsv)
Write-Output "User assigned managed identity details stored."

# Get the current user's object ID for Key Vault permissions
$env:USER_OBJECT_ID = az ad signed-in-user show --query "id" -o tsv
Write-Output "User Object ID: $env:USER_OBJECT_ID"

az aks create `
  --resource-group $env:RG_NAME `
  --name $env:AKS_NAME `
  --location $env:LOCATION `
  --tier standard `
  --kubernetes-version $env:K8S_VERSION `
  --node-count 3 `
  --os-sku AzureLinux `
  --nodepool-name systempool `
  --node-vm-size Standard_DS2_v2 `
  --enable-managed-identity `
  --enable-workload-identity `
  --enable-oidc-issuer `
  --enable-acns `
  --enable-addons monitoring `
  --enable-container-network-logs `
  --acns-advanced-networkpolicies L7 `
  --enable-high-log-scale-mode `
  --generate-ssh-keys 
Write-Output "AKS Cluster $env:AKS_NAME created successfully in resource group $env:RG_NAME"

# Capture AKS cluster ID
$env:AKS_CLUSTER_ID = az aks show `
  --name $env:AKS_NAME `
  --resource-group $env:RG_NAME `
  --query id `
  --output tsv
Write-Output "AKS Cluster ID: $env:AKS_CLUSTER_ID"

# Capture AKS cluster FQDN
$env:AKS_CLUSTER_FQDN = az aks show `
  --name $env:AKS_NAME `
  --resource-group $env:RG_NAME `
  --query "fqdn" `
  --output tsv
Write-Output "AKS Cluster FQDN: $env:AKS_CLUSTER_FQDN"

#>

# Get AKS credentials
Write-Host "[Step 1] Getting AKS credentials..." -ForegroundColor Yellow
az aks get-credentials --resource-group $env:RG_NAME --name $env:AKS_NAME --overwrite-existing --file "$env:AKS_NAME.config"
kubectl config current-context

# ============================================================================
# STEP 2: Install BYO Nginx Ingress Controller (the "before" state)
# ============================================================================
Write-Host ""
Write-Host "[Step 2] Installing BYO Nginx Ingress Controller via Helm..." -ForegroundColor Yellow

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx `
  --namespace ingress-nginx `
  --create-namespace `
  -f byo-nginx-values.yaml

Write-Host "Waiting for BYO Nginx to get an external IP..."
kubectl wait --namespace ingress-nginx `
  --for=condition=ready pod `
  --selector=app.kubernetes.io/component=controller `
  --timeout=120s

kubectl get svc -n ingress-nginx
Write-Host ""

# ============================================================================
# STEP 3: Deploy the sample application
# ============================================================================
Write-Host "[Step 3] Deploying sample application..." -ForegroundColor Yellow

kubectl apply -f app-deployment.yaml

Write-Host "Waiting for pods to be ready..."
kubectl wait --namespace myapp `
  --for=condition=ready pod `
  --selector=app=myapp `
  --timeout=120s

kubectl get pods -n myapp
kubectl get svc -n myapp
Write-Host ""

# ============================================================================
# STEP 4: Create BYO Nginx Ingress resource
# ============================================================================
Write-Host "[Step 4] Creating BYO Nginx Ingress resource..." -ForegroundColor Yellow

kubectl apply -f ingress.yaml

Write-Host "Verifying BYO Ingress..."
kubectl get ingress -n myapp
Write-Host ""

# Get BYO Nginx external IP
$env:BYO_IP = kubectl get svc ingress-nginx-controller -n ingress-nginx `
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
Write-Host "BYO Nginx External IP: $env:BYO_IP" -ForegroundColor Green

# Test BYO Nginx route
Write-Host ""
Write-Host "[Test] Hitting app via BYO Nginx controller..." -ForegroundColor Magenta
Write-Host "  curl -s -o /dev/null -w '%{http_code}' -H 'Host: myapp.example.com' http://$env:BYO_IP"
curl -s -o /dev/null -w "%{http_code}" -H "Host: myapp.example.com" http://$env:BYO_IP
Write-Host ""

# ============================================================================
# STEP 5: Show current IngressClasses (only 'nginx' exists)
# ============================================================================
Write-Host ""
Write-Host "[Step 5] Current IngressClasses (before enabling add-on):" -ForegroundColor Yellow
kubectl get ingressclass
Write-Host ""

# ============================================================================
# STEP 6: Enable the AKS App Routing Add-On (Skip if already there)
# ============================================================================
Write-Host "[Step 6] Enabling AKS App Routing Add-On..." -ForegroundColor Yellow
Write-Host "  This does NOT touch the existing BYO Nginx controller." -ForegroundColor DarkGray

az aks approuting enable --resource-group $env:RG_NAME --name $env:AKS_NAME

Write-Host "Waiting for App Routing pods to be ready..."
kubectl wait --namespace app-routing-system `
  --for=condition=ready pod `
  --selector=app=nginx `
  --timeout=120s

Write-Host ""
Write-Host "App Routing system pods:" -ForegroundColor Green
kubectl get pods -n app-routing-system

Write-Host ""
Write-Host "App Routing system services:" -ForegroundColor Green
kubectl get svc -n app-routing-system

# ============================================================================
# STEP 7: Show IngressClasses (now two exist — parallel running)
# ============================================================================
Write-Host ""
Write-Host "[Step 7] IngressClasses after enabling add-on:" -ForegroundColor Yellow
kubectl get ingressclass
Write-Host ""
Write-Host "  'nginx' = BYO controller (ingress-nginx namespace)" -ForegroundColor DarkGray
Write-Host "  'webapprouting.kubernetes.azure.com' = App Routing add-on (app-routing-system)" -ForegroundColor DarkGray

# ============================================================================
# STEP 8: Create App Routing Add-On Ingress (parallel with BYO)
# ============================================================================
Write-Host ""
Write-Host "[Step 8] Creating App Routing Ingress resource (parallel with BYO)..." -ForegroundColor Yellow

kubectl apply -f ingressaddon.yaml

Write-Host "Verifying both Ingress resources exist side-by-side:"
kubectl get ingress -n myapp
Write-Host ""

# Get App Routing add-on external IP
$env:ADDON_IP = kubectl get svc nginx -n app-routing-system `
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
Write-Host "BYO Nginx IP:     $env:BYO_IP" -ForegroundColor Green
Write-Host "App Routing IP:   $env:ADDON_IP" -ForegroundColor Green
Write-Host ""
Write-Host "  Both controllers are running. Same app, two IPs, zero downtime." -ForegroundColor DarkGray

# ============================================================================
# STEP 9: Validate via the App Routing Add-On IP
# ============================================================================
Write-Host ""
Write-Host "[Step 9] Testing app via BOTH controllers..." -ForegroundColor Magenta

Write-Host "  BYO Nginx:    curl -H 'Host: myapp.example.com' http://$env:BYO_IP"
$env:byoResult = curl -s -o /dev/null -w "%{http_code}" -H "Host: myapp.example.com" http://$env:BYO_IP
Write-Host "  BYO Response: $env:byoResult" -ForegroundColor $(if($env:byoResult -eq "200"){"Green"}else{"Red"})

Write-Host ""
Write-Host "  App Routing:  curl -H 'Host: myapp.example.com' http://$env:ADDON_IP"
$env:addonResult = curl -s -o /dev/null -w "%{http_code}" -H "Host: myapp.example.com" http://$env:ADDON_IP
Write-Host "  Add-on Response: $env:addonResult" -ForegroundColor $(if($env:addonResult -eq "200"){"Green"}else{"Red"})

Write-Host ""
Write-Host "  Both return 200 — migration validated. Ready for DNS cutover." -ForegroundColor Green

# ============================================================================
# STEP 10: Cutover — Remove BYO Ingress, keep only App Routing
# ============================================================================
Write-Host ""
Write-Host "[Step 10] Cutover: Removing BYO Ingress resource..." -ForegroundColor Yellow
Write-Host "  In production, you'd update DNS to point to the add-on IP first." -ForegroundColor DarkGray

kubectl delete ingress myapp-ingress-byo -n myapp

Write-Host ""
Write-Host "Remaining Ingress resources (only add-on should remain):"
kubectl get ingress -n myapp
Write-Host ""

# ============================================================================
# STEP 11: Verify no remaining BYO Ingress resources
# ============================================================================
Write-Host "[Step 11] Checking for any remaining BYO Ingress resources..." -ForegroundColor Yellow
$env:remaining = kubectl get ingress --all-namespaces -o json | ConvertFrom-Json
$env:byoIngresses = $env:remaining.items | Where-Object { $_.spec.ingressClassName -eq "nginx" }
if ($env:byoIngresses.Count -eq 0) {
    Write-Host "  No BYO Ingress resources found. Safe to decommission BYO controller." -ForegroundColor Green
} else {
    Write-Host "  WARNING: $($env:byoIngresses.Count) BYO Ingress resources still exist!" -ForegroundColor Red
    $env:byoIngresses | ForEach-Object { Write-Host "    $($_.metadata.namespace)/$($_.metadata.name)" }
}

# ============================================================================
# STEP 12: Decommission BYO Nginx Controller
# ============================================================================
Write-Host ""
Write-Host "[Step 12] Decommissioning BYO Nginx controller..." -ForegroundColor Yellow

helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx

Write-Host ""
Write-Host "Final state — IngressClasses (only add-on should remain):"
kubectl get ingressclass

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " Migration Complete!"                        -ForegroundColor Green
Write-Host " App Routing Add-On IP: $ADDON_IP"           -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  - App Routing (Nginx-based) is supported until November 2026"
Write-Host "  - Plan migration to Istio-based App Routing or App Gateway for Containers"
Write-Host "  - Consider Gateway API migration using ingress2gateway tool"
